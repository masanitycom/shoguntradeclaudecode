-- 既存の関数をすべて削除してから新しい関数を作成

-- 1. 既存の関数をすべて削除
DROP FUNCTION IF EXISTS admin_create_backup(DATE);
DROP FUNCTION IF EXISTS admin_create_backup(DATE, TEXT);
DROP FUNCTION IF EXISTS admin_delete_weekly_rates(DATE);
DROP FUNCTION IF EXISTS admin_delete_weekly_rates(DATE, TEXT);
DROP FUNCTION IF EXISTS admin_restore_from_backup(DATE);
DROP FUNCTION IF EXISTS admin_restore_from_backup(DATE, TIMESTAMP WITH TIME ZONE);
DROP FUNCTION IF EXISTS get_backup_list();
DROP FUNCTION IF EXISTS get_system_status();
DROP FUNCTION IF EXISTS get_weekly_rates_with_groups();
DROP FUNCTION IF EXISTS show_available_groups();

-- 2. バックアップテーブルの制約を緩和
ALTER TABLE group_weekly_rates_backup 
ALTER COLUMN week_end_date DROP NOT NULL;

-- 3. show_available_groups関数を作成
CREATE OR REPLACE FUNCTION show_available_groups()
RETURNS TABLE(
    group_id UUID,
    group_name TEXT,
    nft_count BIGINT,
    total_investment NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        drg.id as group_id,
        drg.group_name,
        COUNT(n.id) as nft_count,
        COALESCE(SUM(n.price), 0) as total_investment
    FROM daily_rate_groups drg
    LEFT JOIN nfts n ON n.daily_rate_group_id = drg.id
    GROUP BY drg.id, drg.group_name
    ORDER BY drg.group_name;
END;
$$ LANGUAGE plpgsql;

-- 4. get_weekly_rates_with_groups関数を作成
CREATE OR REPLACE FUNCTION get_weekly_rates_with_groups()
RETURNS TABLE(
    id UUID,
    week_start_date DATE,
    week_end_date DATE,
    weekly_rate NUMERIC,
    monday_rate NUMERIC,
    tuesday_rate NUMERIC,
    wednesday_rate NUMERIC,
    thursday_rate NUMERIC,
    friday_rate NUMERIC,
    group_name TEXT,
    distribution_method TEXT,
    has_backup BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwr.id,
        gwr.week_start_date,
        gwr.week_end_date,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        drg.group_name,
        COALESCE(gwr.distribution_method, 'random') as distribution_method,
        EXISTS(
            SELECT 1 FROM group_weekly_rates_backup gwrb 
            WHERE gwrb.week_start_date = gwr.week_start_date
        ) as has_backup
    FROM group_weekly_rates gwr
    JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    ORDER BY gwr.week_start_date DESC, drg.group_name;
END;
$$ LANGUAGE plpgsql;

-- 5. get_system_status関数を作成
CREATE OR REPLACE FUNCTION get_system_status()
RETURNS TABLE(
    total_users INTEGER,
    active_nfts INTEGER,
    pending_rewards NUMERIC,
    last_calculation TEXT,
    current_week_rates INTEGER,
    total_backups INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM users WHERE is_active = true) as total_users,
        (SELECT COUNT(*)::INTEGER FROM user_nfts WHERE is_active = true) as active_nfts,
        (SELECT COALESCE(SUM(reward_amount), 0) FROM daily_rewards WHERE reward_date >= CURRENT_DATE - INTERVAL '7 days') as pending_rewards,
        (SELECT COALESCE(MAX(created_at)::TEXT, '未実行') FROM daily_rewards) as last_calculation,
        (SELECT COUNT(DISTINCT week_start_date)::INTEGER FROM group_weekly_rates) as current_week_rates,
        (SELECT COUNT(*)::INTEGER FROM group_weekly_rates_backup) as total_backups;
END;
$$ LANGUAGE plpgsql;

-- 6. get_backup_list関数を作成
CREATE OR REPLACE FUNCTION get_backup_list()
RETURNS TABLE(
    week_start_date DATE,
    backup_timestamp TIMESTAMP WITH TIME ZONE,
    backup_reason TEXT,
    group_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwrb.week_start_date,
        gwrb.backup_timestamp,
        COALESCE(gwrb.backup_reason, 'Unknown') as backup_reason,
        COUNT(*) as group_count
    FROM group_weekly_rates_backup gwrb
    GROUP BY gwrb.week_start_date, gwrb.backup_timestamp, gwrb.backup_reason
    ORDER BY gwrb.backup_timestamp DESC;
END;
$$ LANGUAGE plpgsql;

-- 7. admin_create_backup関数を作成
CREATE OR REPLACE FUNCTION admin_create_backup(
    p_week_start_date DATE,
    p_reason TEXT DEFAULT 'Manual backup'
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    backup_count INTEGER := 0;
BEGIN
    -- 指定週のデータをバックアップ（week_end_dateを計算）
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
        COALESCE(gwr.week_end_date, gwr.week_start_date + INTERVAL '4 days') as week_end_date,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        COALESCE(gwr.distribution_method, 'random'),
        p_reason,
        NOW()
    FROM group_weekly_rates gwr
    WHERE gwr.week_start_date = p_week_start_date;
    
    GET DIAGNOSTICS backup_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true,
        format('%sのデータを%s件バックアップしました', p_week_start_date::TEXT, backup_count);
END;
$$ LANGUAGE plpgsql;

-- 8. admin_delete_weekly_rates関数を作成
CREATE OR REPLACE FUNCTION admin_delete_weekly_rates(
    p_week_start_date DATE
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    deleted_count INTEGER := 0;
    backup_result RECORD;
BEGIN
    -- まずバックアップを作成
    SELECT * INTO backup_result 
    FROM admin_create_backup(p_week_start_date, 'Before deletion') 
    LIMIT 1;
    
    IF NOT backup_result.success THEN
        RETURN QUERY SELECT 
            false,
            'バックアップ作成に失敗: ' || backup_result.message;
        RETURN;
    END IF;
    
    -- データを削除
    DELETE FROM group_weekly_rates 
    WHERE week_start_date = p_week_start_date;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true,
        format('%sの週利設定を%s件削除しました（バックアップ済み）', p_week_start_date::TEXT, deleted_count);
        
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 
        false,
        '削除エラー: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- 9. admin_restore_from_backup関数を作成
CREATE OR REPLACE FUNCTION admin_restore_from_backup(
    p_week_start_date DATE,
    p_backup_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    restored_count INTEGER := 0;
    backup_timestamp TIMESTAMP WITH TIME ZONE;
BEGIN
    -- バックアップタイムスタンプが指定されていない場合は最新を使用
    IF p_backup_timestamp IS NULL THEN
        SELECT MAX(backup_timestamp) INTO backup_timestamp
        FROM group_weekly_rates_backup
        WHERE week_start_date = p_week_start_date;
    ELSE
        backup_timestamp := p_backup_timestamp;
    END IF;
    
    IF backup_timestamp IS NULL THEN
        RETURN QUERY SELECT 
            false,
            format('%sのバックアップが見つかりません', p_week_start_date::TEXT);
        RETURN;
    END IF;
    
    -- 既存データを削除
    DELETE FROM group_weekly_rates WHERE week_start_date = p_week_start_date;
    
    -- バックアップから復元（week_end_dateを計算）
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
        COALESCE(week_end_date, week_start_date + INTERVAL '4 days') as week_end_date,
        weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        COALESCE(distribution_method, 'random')
    FROM group_weekly_rates_backup
    WHERE week_start_date = p_week_start_date 
    AND backup_timestamp = admin_restore_from_backup.backup_timestamp;
    
    GET DIAGNOSTICS restored_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true,
        format('%sの週利設定を%s件復元しました', p_week_start_date::TEXT, restored_count);
        
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 
        false,
        '復元エラー: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- 10. 権限設定
GRANT EXECUTE ON FUNCTION show_available_groups() TO authenticated;
GRANT EXECUTE ON FUNCTION get_weekly_rates_with_groups() TO authenticated;
GRANT EXECUTE ON FUNCTION get_system_status() TO authenticated;
GRANT EXECUTE ON FUNCTION get_backup_list() TO authenticated;
GRANT EXECUTE ON FUNCTION admin_create_backup(DATE, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_delete_weekly_rates(DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_restore_from_backup(DATE, TIMESTAMP WITH TIME ZONE) TO authenticated;

SELECT 'All backup functions recreated successfully!' as status;
