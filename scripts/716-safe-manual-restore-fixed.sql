-- 安全な手動設定復元（重複制約対応版）

-- 1. 重複制約を考慮した復元処理
DO $$
DECLARE
    backup_record RECORD;
    restore_count INTEGER := 0;
    main_columns TEXT[];
    backup_columns TEXT[];
    common_columns TEXT[];
    conflict_count INTEGER := 0;
BEGIN
    -- メインテーブルのカラム一覧取得（システムカラム除外）
    SELECT ARRAY_AGG(column_name ORDER BY ordinal_position) INTO main_columns
    FROM information_schema.columns 
    WHERE table_name = 'group_weekly_rates'
    AND column_name NOT IN ('created_at', 'updated_at', 'id');
    
    -- バックアップテーブルのカラム一覧取得（バックアップ専用カラム除外）
    SELECT ARRAY_AGG(column_name ORDER BY ordinal_position) INTO backup_columns
    FROM information_schema.columns 
    WHERE table_name = 'group_weekly_rates_backup'
    AND column_name NOT IN ('backup_timestamp', 'backup_reason', 'id', 'original_id');
    
    -- 共通カラムを特定
    SELECT ARRAY_AGG(col) INTO common_columns
    FROM (
        SELECT UNNEST(main_columns) as col
        INTERSECT
        SELECT UNNEST(backup_columns) as col
    ) t;
    
    RAISE NOTICE 'Common columns for restoration: %', common_columns;
    
    -- 手動設定のバックアップを特定して復元
    FOR backup_record IN 
        SELECT DISTINCT ON (week_start_date, group_id) 
            week_start_date,
            group_id,
            backup_timestamp,
            backup_reason
        FROM group_weekly_rates_backup
        WHERE backup_reason LIKE '%Manual%' 
           OR backup_reason LIKE '%手動%'
           OR backup_reason LIKE '%admin%'
           OR backup_reason LIKE '%ADMIN_MANUAL%'
           OR (backup_reason NOT LIKE '%automatic%' AND backup_reason NOT LIKE '%Auto%')
        ORDER BY week_start_date, group_id, backup_timestamp DESC
    LOOP
        BEGIN
            -- 既存データを削除（重複制約回避）
            DELETE FROM group_weekly_rates 
            WHERE week_start_date = backup_record.week_start_date 
            AND group_id = backup_record.group_id;
            
            -- 動的SQLで復元（共通カラムのみ使用、重複制約対応）
            EXECUTE format(
                'INSERT INTO group_weekly_rates (%s, created_at, updated_at) 
                 SELECT %s, NOW(), NOW()
                 FROM group_weekly_rates_backup 
                 WHERE week_start_date = $1 AND group_id = $2 AND backup_timestamp = $3',
                array_to_string(common_columns, ', '),
                array_to_string(common_columns, ', ')
            ) USING backup_record.week_start_date, backup_record.group_id, backup_record.backup_timestamp;
            
            restore_count := restore_count + 1;
            RAISE NOTICE 'Restored manual settings for week: % group: %', 
                backup_record.week_start_date, backup_record.group_id;
                
        EXCEPTION 
            WHEN unique_violation THEN
                conflict_count := conflict_count + 1;
                RAISE NOTICE 'Skipped duplicate entry for week: % group: %', 
                    backup_record.week_start_date, backup_record.group_id;
            WHEN OTHERS THEN
                RAISE NOTICE 'Error restoring week: % group: % - %', 
                    backup_record.week_start_date, backup_record.group_id, SQLERRM;
        END;
    END LOOP;

    RAISE NOTICE 'Manual settings restoration completed. Restored: %, Conflicts: %', 
        restore_count, conflict_count;
        
    -- 復元できなかった場合の代替処理
    IF restore_count = 0 THEN
        RAISE NOTICE 'No manual backups found. Checking for any recent backups...';
        
        -- 最新のバックアップから復元を試行
        FOR backup_record IN 
            SELECT DISTINCT ON (week_start_date, group_id) 
                week_start_date,
                group_id,
                backup_timestamp,
                backup_reason
            FROM group_weekly_rates_backup
            WHERE backup_timestamp > (NOW() - INTERVAL '7 days')::TEXT
            ORDER BY week_start_date, group_id, backup_timestamp DESC
            LIMIT 10
        LOOP
            BEGIN
                -- 既存データを削除
                DELETE FROM group_weekly_rates 
                WHERE week_start_date = backup_record.week_start_date 
                AND group_id = backup_record.group_id;
                
                -- 復元実行
                EXECUTE format(
                    'INSERT INTO group_weekly_rates (%s, created_at, updated_at) 
                     SELECT %s, NOW(), NOW()
                     FROM group_weekly_rates_backup 
                     WHERE week_start_date = $1 AND group_id = $2 AND backup_timestamp = $3',
                    array_to_string(common_columns, ', '),
                    array_to_string(common_columns, ', ')
                ) USING backup_record.week_start_date, backup_record.group_id, backup_record.backup_timestamp;
                
                restore_count := restore_count + 1;
                RAISE NOTICE 'Restored recent backup for week: % group: %', 
                    backup_record.week_start_date, backup_record.group_id;
                    
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE 'Error restoring recent backup: %', SQLERRM;
            END;
        END LOOP;
    END IF;
END;
$$;

-- 2. 復元結果の詳細確認
SELECT 
    'RESTORATION RESULTS' as section,
    week_start_date,
    COALESCE(group_name, 'Group-' || group_id::TEXT) as group_identifier,
    weekly_rate * 100 as weekly_percent,
    distribution_method,
    created_at,
    updated_at
FROM group_weekly_rates
ORDER BY week_start_date DESC, group_name;

-- 3. バックアップ状況の確認
SELECT 
    'BACKUP ANALYSIS' as section,
    backup_reason,
    COUNT(*) as backup_count,
    MIN(backup_timestamp) as earliest_backup,
    MAX(backup_timestamp) as latest_backup
FROM group_weekly_rates_backup
GROUP BY backup_reason
ORDER BY latest_backup DESC;
