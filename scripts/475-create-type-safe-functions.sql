-- 型安全な管理画面用関数を作成

-- 1. まず型を正確に特定
DO $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN 
        SELECT column_name, data_type, character_maximum_length
        FROM information_schema.columns 
        WHERE table_name = 'daily_rate_groups'
        ORDER BY ordinal_position
    LOOP
        RAISE NOTICE 'Column: %, Type: %, Length: %', rec.column_name, rec.data_type, rec.character_maximum_length;
    END LOOP;
END $$;

-- 2. 型安全な週利サマリー関数を作成
CREATE OR REPLACE FUNCTION get_admin_weekly_rates_summary()
RETURNS TABLE(
    group_id UUID,
    group_name CHARACTER VARYING(50),
    daily_rate_limit NUMERIC,
    rate_display TEXT,
    nft_count BIGINT,
    weekly_rate NUMERIC,
    weekly_rate_percent NUMERIC,
    week_start_date DATE,
    has_weekly_setting BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        drg.id,
        drg.group_name,
        drg.daily_rate_limit,
        (drg.daily_rate_limit * 100)::TEXT || '%',
        COUNT(n.id),
        COALESCE(gwr.weekly_rate, 0::NUMERIC),
        COALESCE(gwr.weekly_rate * 100, 0::NUMERIC),
        gwr.week_start_date,
        (gwr.id IS NOT NULL)
    FROM daily_rate_groups drg
    LEFT JOIN nfts n ON n.daily_rate_limit = drg.daily_rate_limit AND n.is_active = true
    LEFT JOIN group_weekly_rates gwr ON gwr.group_id = drg.id 
        AND gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)::DATE
    GROUP BY drg.id, drg.group_name, drg.daily_rate_limit, 
             gwr.id, gwr.weekly_rate, gwr.week_start_date
    ORDER BY drg.daily_rate_limit;
END $$;

-- 3. 週利設定取得関数
CREATE OR REPLACE FUNCTION get_weekly_rates_for_admin()
RETURNS TABLE(
    id UUID,
    group_id UUID,
    group_name CHARACTER VARYING(50),
    week_start_date DATE,
    week_end_date DATE,
    weekly_rate NUMERIC,
    monday_rate NUMERIC,
    tuesday_rate NUMERIC,
    wednesday_rate NUMERIC,
    thursday_rate NUMERIC,
    friday_rate NUMERIC,
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
        (gwr.week_start_date + INTERVAL '6 days')::DATE,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        gwr.created_at
    FROM group_weekly_rates gwr
    JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit;
END $$;

-- 4. グループ情報取得関数（型を正確に指定）
CREATE OR REPLACE FUNCTION get_daily_rate_groups_for_admin()
RETURNS TABLE(
    id UUID,
    group_name CHARACTER VARYING(50),
    daily_rate_limit NUMERIC,
    description TEXT,
    nft_count BIGINT,
    created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        drg.id,
        drg.group_name,
        drg.daily_rate_limit,
        drg.description::TEXT,
        COUNT(n.id),
        drg.created_at
    FROM daily_rate_groups drg
    LEFT JOIN nfts n ON n.daily_rate_limit = drg.daily_rate_limit AND n.is_active = true
    GROUP BY drg.id, drg.group_name, drg.daily_rate_limit, drg.description, drg.created_at
    ORDER BY drg.daily_rate_limit;
END $$;

-- 5. システム状況取得関数（変数名の曖昧性を解決）
CREATE OR REPLACE FUNCTION get_system_status_for_admin()
RETURNS TABLE(
    active_user_nfts INTEGER,
    total_user_nfts INTEGER,
    active_nfts INTEGER,
    current_week_rates INTEGER,
    is_weekday BOOLEAN,
    day_of_week INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    today_dow INTEGER;
    current_week_start DATE;
BEGIN
    today_dow := EXTRACT(DOW FROM CURRENT_DATE);
    current_week_start := DATE_TRUNC('week', CURRENT_DATE)::DATE;
    
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM user_nfts WHERE is_active = true AND current_investment > 0),
        (SELECT COUNT(*)::INTEGER FROM user_nfts),
        (SELECT COUNT(*)::INTEGER FROM nfts WHERE is_active = true),
        (SELECT COUNT(*)::INTEGER FROM group_weekly_rates WHERE group_weekly_rates.week_start_date = current_week_start),
        (today_dow BETWEEN 1 AND 5),
        today_dow;
END $$;

-- 6. 権限設定
GRANT EXECUTE ON FUNCTION get_admin_weekly_rates_summary() TO authenticated;
GRANT EXECUTE ON FUNCTION get_weekly_rates_for_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION get_daily_rate_groups_for_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION get_system_status_for_admin() TO authenticated;

-- 7. 関数テスト
SELECT '🧪 週利サマリーテスト' as section, COUNT(*) as count FROM get_admin_weekly_rates_summary();
SELECT '🧪 週利設定テスト' as section, COUNT(*) as count FROM get_weekly_rates_for_admin();
SELECT '🧪 グループ情報テスト' as section, COUNT(*) as count FROM get_daily_rate_groups_for_admin();
SELECT '🧪 システム状況テスト' as section, * FROM get_system_status_for_admin();
