-- 安全な手動設定復元（構造確認後）

-- 1. 実際のテーブル構造に基づいた復元処理
DO $$
DECLARE
    backup_record RECORD;
    restore_count INTEGER := 0;
    main_columns TEXT[];
    backup_columns TEXT[];
    common_columns TEXT[];
BEGIN
    -- メインテーブルのカラム一覧取得
    SELECT ARRAY_AGG(column_name ORDER BY ordinal_position) INTO main_columns
    FROM information_schema.columns 
    WHERE table_name = 'group_weekly_rates'
    AND column_name NOT IN ('created_at', 'updated_at', 'id');
    
    -- バックアップテーブルのカラム一覧取得
    SELECT ARRAY_AGG(column_name ORDER BY ordinal_position) INTO backup_columns
    FROM information_schema.columns 
    WHERE table_name = 'group_weekly_rates_backup'
    AND column_name NOT IN ('backup_timestamp', 'backup_reason', 'id');
    
    -- 共通カラムを特定
    SELECT ARRAY_AGG(col) INTO common_columns
    FROM (
        SELECT UNNEST(main_columns) as col
        INTERSECT
        SELECT UNNEST(backup_columns) as col
    ) t;
    
    RAISE NOTICE 'Common columns: %', common_columns;
    
    -- 最新の手動バックアップを特定して復元
    FOR backup_record IN 
        SELECT DISTINCT ON (week_start_date) 
            week_start_date,
            backup_timestamp
        FROM group_weekly_rates_backup
        WHERE backup_reason LIKE '%Manual%' 
           OR backup_reason LIKE '%手動%'
           OR backup_reason LIKE '%admin%'
           OR backup_reason NOT LIKE '%automatic%'
        ORDER BY week_start_date, backup_timestamp DESC
    LOOP
        -- 現在のデータを削除
        DELETE FROM group_weekly_rates 
        WHERE week_start_date = backup_record.week_start_date;
        
        -- 動的SQLで復元（共通カラムのみ使用）
        EXECUTE format(
            'INSERT INTO group_weekly_rates (%s, created_at, updated_at) 
             SELECT %s, NOW(), NOW()
             FROM group_weekly_rates_backup 
             WHERE week_start_date = $1 AND backup_timestamp = $2',
            array_to_string(common_columns, ', '),
            array_to_string(common_columns, ', ')
        ) USING backup_record.week_start_date, backup_record.backup_timestamp;
        
        restore_count := restore_count + 1;
        RAISE NOTICE 'Restored manual settings for week: %', backup_record.week_start_date;
    END LOOP;

    RAISE NOTICE 'Manual settings restoration completed. Restored % weeks.', restore_count;
END;
$$;

-- 2. 復元結果確認
SELECT 
    'RESTORATION RESULTS' as section,
    week_start_date,
    COALESCE(daily_rate_group, group_name, 'Unknown Group') as group_identifier,
    weekly_rate,
    distribution_method,
    created_at
FROM group_weekly_rates
ORDER BY week_start_date DESC;
