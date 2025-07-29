-- 🔧 管理画面UI関数の完全修正
-- 型の不一致エラーを解決

-- 1. 既存の問題のある関数を削除
DROP FUNCTION IF EXISTS get_weekly_rates_for_admin_ui();
DROP FUNCTION IF EXISTS get_system_status();

-- 2. 管理画面用の週利取得関数を正しい型で作成
CREATE OR REPLACE FUNCTION get_weekly_rates_for_admin_ui()
RETURNS TABLE(
    id UUID,
    group_id UUID,
    group_name CHARACTER VARYING(50),
    week_start_date DATE,
    week_end_date DATE,
    week_number INTEGER,
    weekly_rate NUMERIC,
    monday_rate NUMERIC,
    tuesday_rate NUMERIC,
    wednesday_rate NUMERIC,
    thursday_rate NUMERIC,
    friday_rate NUMERIC,
    distribution_method CHARACTER VARYING(50),
    created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwr.id,
        gwr.group_id,
        drg.group_name,
        gwr.week_start_date,
        gwr.week_end_date,
        gwr.week_number,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        gwr.distribution_method,
        gwr.created_at
    FROM group_weekly_rates gwr
    JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit;
END;
$$;

-- 3. システム状況取得関数を正しい型で作成
CREATE OR REPLACE FUNCTION get_system_status()
RETURNS TABLE(
    active_user_nfts INTEGER,
    total_user_nfts INTEGER,
    active_nfts INTEGER,
    current_week_rates INTEGER,
    is_weekday BOOLEAN,
    day_of_week INTEGER,
    today_calculations INTEGER,
    today_total_rewards NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_week_start_date DATE;
    v_day_of_week INTEGER;
BEGIN
    v_day_of_week := EXTRACT(DOW FROM CURRENT_DATE);
    v_week_start_date := CURRENT_DATE - (v_day_of_week - 1);
    
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM user_nfts WHERE is_active = true AND current_investment > 0),
        (SELECT COUNT(*)::INTEGER FROM user_nfts),
        (SELECT COUNT(*)::INTEGER FROM nfts WHERE is_active = true),
        (SELECT COUNT(*)::INTEGER FROM group_weekly_rates WHERE week_start_date = v_week_start_date),
        (v_day_of_week BETWEEN 1 AND 5),
        v_day_of_week,
        (SELECT COUNT(*)::INTEGER FROM daily_rewards WHERE reward_date = CURRENT_DATE),
        (SELECT COALESCE(SUM(reward_amount), 0) FROM daily_rewards WHERE reward_date = CURRENT_DATE);
END;
$$;

-- 4. 権限設定
GRANT EXECUTE ON FUNCTION get_weekly_rates_for_admin_ui() TO authenticated;
GRANT EXECUTE ON FUNCTION get_system_status() TO authenticated;

-- 5. 関数テスト
SELECT '🧪 週利履歴関数テスト' as test, COUNT(*) as count FROM get_weekly_rates_for_admin_ui();
SELECT '🧪 システム状況関数テスト' as test, * FROM get_system_status();
