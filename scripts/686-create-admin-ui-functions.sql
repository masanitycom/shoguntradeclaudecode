-- 管理画面用の関数を作成

-- 1. システム状況取得関数（エラーを避けるため安全に作成）
DROP FUNCTION IF EXISTS get_system_status();

CREATE OR REPLACE FUNCTION get_system_status()
RETURNS TABLE(
    total_users INTEGER,
    active_nfts INTEGER,
    pending_rewards DECIMAL(10,2),
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
        (SELECT COALESCE(SUM(reward_amount), 0)::DECIMAL(10,2) FROM daily_rewards WHERE reward_date = CURRENT_DATE) as pending_rewards,
        (SELECT COALESCE(MAX(created_at)::TEXT, '未実行') FROM daily_rewards) as last_calculation,
        (SELECT COUNT(*)::INTEGER FROM group_weekly_rates) as current_week_rates,
        0 as total_backups; -- バックアップ機能は後で実装
END;
$$;

-- 2. 週利設定取得関数
DROP FUNCTION IF EXISTS get_weekly_rates_with_groups();

CREATE OR REPLACE FUNCTION get_weekly_rates_with_groups()
RETURNS TABLE(
    id UUID,
    week_start_date DATE,
    week_end_date DATE,
    weekly_rate DECIMAL(10,6),
    monday_rate DECIMAL(10,6),
    tuesday_rate DECIMAL(10,6),
    wednesday_rate DECIMAL(10,6),
    thursday_rate DECIMAL(10,6),
    friday_rate DECIMAL(10,6),
    group_name TEXT,
    distribution_method TEXT,
    has_backup BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwr.id,
        gwr.week_start_date,
        COALESCE(gwr.week_end_date, gwr.week_start_date + 6) as week_end_date,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        COALESCE(gwr.group_name, '全グループ共通') as group_name,
        COALESCE(gwr.distribution_method, 'manual') as distribution_method,
        false as has_backup -- バックアップ機能は後で実装
    FROM group_weekly_rates gwr
    ORDER BY gwr.week_start_date DESC;
END;
$$;

-- 3. バックアップリスト取得関数（空の結果を返す）
DROP FUNCTION IF EXISTS get_backup_list();

CREATE OR REPLACE FUNCTION get_backup_list()
RETURNS TABLE(
    week_start_date DATE,
    backup_timestamp TIMESTAMP,
    backup_reason TEXT,
    group_count INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- 現在はバックアップ機能なしなので空の結果を返す
    RETURN;
END;
$$;

-- 権限設定
GRANT EXECUTE ON FUNCTION get_system_status() TO authenticated;
GRANT EXECUTE ON FUNCTION get_weekly_rates_with_groups() TO authenticated;
GRANT EXECUTE ON FUNCTION get_backup_list() TO authenticated;
