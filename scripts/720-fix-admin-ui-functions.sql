-- 管理UI用の修正された関数群

-- 1. 問題のあるバックアップ関数を削除
DROP FUNCTION IF EXISTS get_backup_list();
DROP FUNCTION IF EXISTS admin_create_backup(DATE, TEXT);
DROP FUNCTION IF EXISTS admin_delete_weekly_rates(DATE);

-- 2. シンプルなバックアップリスト関数
CREATE OR REPLACE FUNCTION get_simple_backup_list()
RETURNS TABLE(
    week_start_date TEXT,
    backup_count INTEGER,
    latest_backup TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'No backups' as week_start_date,
        0 as backup_count,
        'System cleared' as latest_backup
    WHERE NOT EXISTS (SELECT 1 FROM group_weekly_rates_backup);
END;
$$;

-- 3. シンプルなシステム状況関数
CREATE OR REPLACE FUNCTION get_simple_system_status()
RETURNS TABLE(
    total_users INTEGER,
    active_nfts INTEGER,
    pending_rewards DECIMAL,
    last_calculation TEXT,
    current_week_rates INTEGER,
    total_backups INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM users) as total_users,
        (SELECT COUNT(*)::INTEGER FROM user_nfts WHERE is_active = true) as active_nfts,
        0::DECIMAL as pending_rewards,
        'Manual setup mode' as last_calculation,
        (SELECT COUNT(*)::INTEGER FROM group_weekly_rates) as current_week_rates,
        0 as total_backups;
END;
$$;

-- 4. 週利設定用の関数（UIから呼び出し）
CREATE OR REPLACE FUNCTION set_group_weekly_rate_ui(
    p_week_start_date DATE,
    p_group_name TEXT,
    p_weekly_rate DECIMAL
)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM admin_manual_set_weekly_rate(p_week_start_date, p_group_name, p_weekly_rate);
END;
$$;

-- 5. 週利取得用の関数（UIから呼び出し）
CREATE OR REPLACE FUNCTION get_weekly_rates_with_groups_ui()
RETURNS TABLE(
    id TEXT,
    week_start_date DATE,
    week_end_date DATE,
    weekly_rate DECIMAL,
    monday_rate DECIMAL,
    tuesday_rate DECIMAL,
    wednesday_rate DECIMAL,
    thursday_rate DECIMAL,
    friday_rate DECIMAL,
    group_name TEXT,
    distribution_method TEXT,
    has_backup BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwr.id::TEXT,
        gwr.week_start_date,
        gwr.week_end_date,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        gwr.group_name,
        gwr.distribution_method,
        false as has_backup
    FROM group_weekly_rates gwr
    ORDER BY gwr.week_start_date DESC, gwr.group_name;
END;
$$;

-- 6. 権限設定
GRANT EXECUTE ON FUNCTION get_simple_backup_list() TO authenticated;
GRANT EXECUTE ON FUNCTION get_simple_system_status() TO authenticated;
GRANT EXECUTE ON FUNCTION set_group_weekly_rate_ui(DATE, TEXT, DECIMAL) TO authenticated;
GRANT EXECUTE ON FUNCTION get_weekly_rates_with_groups_ui() TO authenticated;

SELECT 'Admin UI functions fixed for manual setup' as status;
