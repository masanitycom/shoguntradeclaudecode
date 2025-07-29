-- 管理画面用の専用関数を作成（型の不一致を修正）

-- 1. まず正確な型を確認してから関数を作成
DO $$
DECLARE
    group_name_type TEXT;
    description_type TEXT;
BEGIN
    -- 実際の型を取得
    SELECT data_type INTO group_name_type
    FROM information_schema.columns 
    WHERE table_name = 'daily_rate_groups' AND column_name = 'group_name';
    
    SELECT data_type INTO description_type
    FROM information_schema.columns 
    WHERE table_name = 'daily_rate_groups' AND column_name = 'description';
    
    RAISE NOTICE 'group_name型: %, description型: %', group_name_type, description_type;
END $$;

-- 2. 週利設定取得関数（型を正確に指定）
CREATE OR REPLACE FUNCTION get_weekly_rates_for_admin()
RETURNS TABLE(
    id UUID,
    group_id UUID,
    group_name VARCHAR(50), -- 実際の型に合わせる
    week_start_date DATE,
    week_end_date DATE,
    week_number INTEGER,
    weekly_rate NUMERIC,
    monday_rate NUMERIC,
    tuesday_rate NUMERIC,
    wednesday_rate NUMERIC,
    thursday_rate NUMERIC,
    friday_rate NUMERIC,
    distribution_method VARCHAR(50),
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
        drg.group_name, -- 型変換なし
        gwr.week_start_date,
        (gwr.week_start_date + INTERVAL '6 days')::DATE as week_end_date,
        EXTRACT(WEEK FROM gwr.week_start_date)::INTEGER as week_number,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        'random_distribution'::VARCHAR(50) as distribution_method,
        gwr.created_at
    FROM group_weekly_rates gwr
    JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit;
END $$;

-- 3. グループ情報取得関数（型を正確に指定）
CREATE OR REPLACE FUNCTION get_daily_rate_groups_for_admin()
RETURNS TABLE(
    id UUID,
    group_name VARCHAR(50), -- 実際の型に合わせる
    daily_rate_limit NUMERIC,
    description VARCHAR(255), -- 実際の型に合わせる
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
        drg.group_name, -- 型変換なし
        drg.daily_rate_limit,
        drg.description, -- 型変換なし
        COUNT(n.id) as nft_count,
        drg.created_at
    FROM daily_rate_groups drg
    LEFT JOIN nfts n ON n.daily_rate_limit = drg.daily_rate_limit AND n.is_active = true
    GROUP BY drg.id, drg.group_name, drg.daily_rate_limit, drg.description, drg.created_at
    ORDER BY drg.daily_rate_limit;
END $$;

-- 4. 管理画面用の週利サマリー関数（問題の関数を修正）
CREATE OR REPLACE FUNCTION get_admin_weekly_rates_summary()
RETURNS TABLE(
    group_id UUID,
    group_name VARCHAR(50), -- 実際の型に合わせる
    daily_rate_limit NUMERIC,
    rate_display VARCHAR(10), -- 実際の型に合わせる
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
        drg.id as group_id,
        drg.group_name, -- 型変換なし
        drg.daily_rate_limit,
        ((drg.daily_rate_limit * 100) || '%')::VARCHAR(10) as rate_display,
        COUNT(n.id) as nft_count,
        COALESCE(gwr.weekly_rate, 0) as weekly_rate,
        COALESCE(gwr.weekly_rate * 100, 0) as weekly_rate_percent,
        gwr.week_start_date,
        CASE WHEN gwr.id IS NOT NULL THEN true ELSE false END as has_weekly_setting
    FROM daily_rate_groups drg
    LEFT JOIN nfts n ON n.daily_rate_limit = drg.daily_rate_limit AND n.is_active = true
    LEFT JOIN group_weekly_rates gwr ON gwr.group_id = drg.id 
        AND gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)::DATE
    GROUP BY drg.id, drg.group_name, drg.daily_rate_limit, 
             gwr.id, gwr.weekly_rate, gwr.week_start_date
    ORDER BY drg.daily_rate_limit;
END $$;

-- 5. システム状況取得関数
CREATE OR REPLACE FUNCTION get_system_status_for_admin()
RETURNS TABLE(
    active_user_nfts INTEGER,
    total_user_nfts INTEGER,
    active_nfts INTEGER,
    current_week_rates INTEGER,
    is_weekday BOOLEAN,
    day_of_week INTEGER,
    current_week_start DATE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    today_dow INTEGER;
    week_start_date DATE;
BEGIN
    -- 曜日を取得（0=日曜日, 1=月曜日, ..., 6=土曜日）
    today_dow := EXTRACT(DOW FROM CURRENT_DATE);
    
    -- 今週の月曜日を計算
    week_start_date := DATE_TRUNC('week', CURRENT_DATE)::DATE;
    
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM user_nfts WHERE is_active = true AND current_investment > 0) as active_user_nfts,
        (SELECT COUNT(*)::INTEGER FROM user_nfts) as total_user_nfts,
        (SELECT COUNT(*)::INTEGER FROM nfts WHERE is_active = true) as active_nfts,
        (SELECT COUNT(*)::INTEGER FROM group_weekly_rates WHERE week_start_date = week_start_date) as current_week_rates,
        (today_dow BETWEEN 1 AND 5) as is_weekday,
        today_dow as day_of_week,
        week_start_date as current_week_start;
END $$;

-- 6. 関数の権限設定
GRANT EXECUTE ON FUNCTION get_weekly_rates_for_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION get_daily_rate_groups_for_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION get_admin_weekly_rates_summary() TO authenticated;
GRANT EXECUTE ON FUNCTION get_system_status_for_admin() TO authenticated;

-- 7. 関数のテスト実行
SELECT '🧪 週利設定取得テスト' as section, COUNT(*) as count FROM get_weekly_rates_for_admin();
SELECT '🧪 グループ情報取得テスト' as section, COUNT(*) as count FROM get_daily_rate_groups_for_admin();
SELECT '🧪 週利サマリーテスト' as section, COUNT(*) as count FROM get_admin_weekly_rates_summary();
SELECT '🧪 システム状況テスト' as section, * FROM get_system_status_for_admin();
