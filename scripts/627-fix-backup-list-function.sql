-- バックアップ一覧表示関数の修正

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

-- システム状況表示関数の修正
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
        (SELECT COALESCE(SUM(amount), 0) FROM daily_rewards WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as pending_rewards,
        (SELECT COALESCE(MAX(created_at)::TEXT, '未実行') FROM daily_rewards) as last_calculation,
        (SELECT COUNT(DISTINCT week_start_date)::INTEGER FROM group_weekly_rates) as current_week_rates,
        (SELECT COUNT(*)::INTEGER FROM group_weekly_rates_backup) as total_backups;
END;
$$ LANGUAGE plpgsql;

-- 権限設定
GRANT EXECUTE ON FUNCTION get_backup_list() TO authenticated;
GRANT EXECUTE ON FUNCTION get_system_status() TO authenticated;
GRANT EXECUTE ON FUNCTION admin_create_backup(DATE, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_delete_weekly_rates(DATE, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_restore_from_backup(DATE, TIMESTAMP WITH TIME ZONE) TO authenticated;

SELECT 'Backup list function fixed successfully!' as status;
