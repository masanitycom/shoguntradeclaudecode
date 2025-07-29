-- 管理画面用関数修正

DROP FUNCTION IF EXISTS get_weekly_rates_with_groups();
DROP FUNCTION IF EXISTS get_system_status();

-- 週利データ取得（管理画面用）
CREATE OR REPLACE FUNCTION get_weekly_rates_with_groups()
RETURNS TABLE (
    id TEXT,
    week_start_date TEXT,
    week_end_date TEXT,
    weekly_rate NUMERIC,
    monday_rate NUMERIC,
    tuesday_rate NUMERIC,
    wednesday_rate NUMERIC,
    thursday_rate NUMERIC,
    friday_rate NUMERIC,
    group_name TEXT,
    distribution_method TEXT
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwr.id::TEXT,
        gwr.week_start_date::TEXT,
        gwr.week_end_date::TEXT,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        drg.group_name::TEXT,
        COALESCE(gwr.distribution_method, 'random')::TEXT
    FROM group_weekly_rates gwr
    JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit;
END;
$$;

-- システム状況取得
CREATE OR REPLACE FUNCTION get_system_status()
RETURNS TABLE (
    total_users BIGINT,
    active_nfts BIGINT,
    pending_rewards NUMERIC,
    last_calculation TEXT,
    current_week_rates BIGINT
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM users WHERE is_admin = false)::BIGINT,
        (SELECT COUNT(*) FROM user_nfts WHERE is_active = true)::BIGINT,
        (SELECT COALESCE(SUM(reward_amount), 0) FROM daily_rewards WHERE created_at >= CURRENT_DATE - INTERVAL '7 days')::NUMERIC,
        (SELECT COALESCE(MAX(created_at)::TEXT, 'Never') FROM daily_rewards)::TEXT,
        (SELECT COUNT(DISTINCT week_start_date) FROM group_weekly_rates WHERE week_start_date >= CURRENT_DATE - INTERVAL '7 days')::BIGINT;
END;
$$;

-- グループ別設定用関数
CREATE OR REPLACE FUNCTION set_custom_weekly_rate(
    p_week_start_date DATE,
    p_weekly_rate NUMERIC
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    records_created INTEGER
) AS $$
DECLARE
    group_record RECORD;
    records_count INTEGER := 0;
BEGIN
    FOR group_record IN 
        SELECT id, group_name FROM daily_rate_groups ORDER BY daily_rate_limit
    LOOP
        PERFORM set_group_weekly_rate(p_week_start_date, group_record.group_name, p_weekly_rate);
        records_count := records_count + 1;
    END LOOP;
    
    RETURN QUERY SELECT 
        true,
        format('全グループに週利%s%%を設定（%s件）', p_weekly_rate, records_count),
        records_count;
END;
$$ LANGUAGE plpgsql;
