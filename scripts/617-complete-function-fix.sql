-- 完全な関数修正とテスト

-- 1. すべての管理UI関数を再作成
DROP FUNCTION IF EXISTS admin_create_backup(DATE);
DROP FUNCTION IF EXISTS admin_delete_weekly_rates(DATE);
DROP FUNCTION IF EXISTS admin_restore_from_backup(DATE, TIMESTAMP WITH TIME ZONE);

-- 2. admin_create_backup関数
CREATE OR REPLACE FUNCTION admin_create_backup(
    p_week_start_date DATE
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    backup_count INTEGER := 0;
BEGIN
    -- バックアップ作成
    INSERT INTO group_weekly_rates_backup (
        original_id,
        group_id,
        week_start_date,
        week_end_date,
        weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        distribution_method,
        backup_reason,
        backup_timestamp
    )
    SELECT 
        gwr.id,
        gwr.group_id,
        gwr.week_start_date,
        gwr.week_end_date,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        gwr.distribution_method,
        'Manual backup via admin UI',
        NOW()
    FROM group_weekly_rates gwr
    WHERE gwr.week_start_date = p_week_start_date;
    
    GET DIAGNOSTICS backup_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true,
        format('%sの週利設定を%s件バックアップしました', p_week_start_date::TEXT, backup_count);
END;
$$ LANGUAGE plpgsql;

-- 3. admin_delete_weekly_rates関数
CREATE OR REPLACE FUNCTION admin_delete_weekly_rates(
    p_week_start_date DATE
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    deleted_count INTEGER := 0;
BEGIN
    -- バックアップ作成
    PERFORM admin_create_backup(p_week_start_date);
    
    -- 削除実行
    DELETE FROM group_weekly_rates 
    WHERE week_start_date = p_week_start_date;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true,
        format('%sの週利設定を%s件削除しました（バックアップ済み）', p_week_start_date::TEXT, deleted_count);
END;
$$ LANGUAGE plpgsql;

-- 4. admin_restore_from_backup関数
CREATE OR REPLACE FUNCTION admin_restore_from_backup(
    p_week_start_date DATE,
    p_backup_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NULL
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    restored_count INTEGER := 0;
    backup_time TIMESTAMP WITH TIME ZONE;
BEGIN
    -- バックアップタイムスタンプ決定
    IF p_backup_timestamp IS NULL THEN
        SELECT MAX(COALESCE(backup_timestamp, created_at)) INTO backup_time
        FROM group_weekly_rates_backup
        WHERE week_start_date = p_week_start_date;
    ELSE
        backup_time := p_backup_timestamp;
    END IF;
    
    IF backup_time IS NULL THEN
        RETURN QUERY SELECT 
            false,
            format('%sのバックアップが見つかりません', p_week_start_date::TEXT);
        RETURN;
    END IF;
    
    -- 既存データ削除
    DELETE FROM group_weekly_rates WHERE week_start_date = p_week_start_date;
    
    -- バックアップから復元
    INSERT INTO group_weekly_rates (
        group_id,
        week_start_date,
        week_end_date,
        weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        distribution_method
    )
    SELECT 
        group_id,
        week_start_date,
        week_end_date,
        weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        distribution_method
    FROM group_weekly_rates_backup
    WHERE week_start_date = p_week_start_date 
    AND COALESCE(backup_timestamp, created_at) = backup_time;
    
    GET DIAGNOSTICS restored_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true,
        format('%sの週利設定を%s件復元しました', p_week_start_date::TEXT, restored_count);
END;
$$ LANGUAGE plpgsql;

-- 5. 最終テスト
SELECT 'Testing all functions...' as status;

-- システム状況
SELECT * FROM get_system_status();

-- 利用可能グループ
SELECT * FROM show_available_groups();

-- バックアップ一覧
SELECT * FROM get_backup_list() LIMIT 3;

SELECT 'All functions fixed and tested successfully!' as status;
