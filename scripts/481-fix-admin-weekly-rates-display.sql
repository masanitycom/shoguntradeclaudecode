-- 管理画面の週利設定表示を修正

-- 1. 管理画面用の週利取得関数を作成
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
    distribution_method TEXT,
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
        (gwr.week_start_date + INTERVAL '6 days')::DATE as week_end_date,
        EXTRACT(WEEK FROM gwr.week_start_date)::INTEGER as week_number,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        'ランダム配分'::TEXT as distribution_method,
        gwr.created_at
    FROM group_weekly_rates gwr
    JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit;
END $$;

-- 2. 権限設定
GRANT EXECUTE ON FUNCTION get_weekly_rates_for_admin_ui() TO authenticated;

-- 3. 関数テスト
SELECT 
    '🧪 週利履歴表示テスト' as section,
    COUNT(*) as total_records,
    COUNT(DISTINCT week_start_date) as unique_weeks
FROM get_weekly_rates_for_admin_ui();

-- 4. 詳細表示テスト
SELECT 
    '📋 週利履歴詳細' as section,
    week_start_date,
    week_end_date,
    group_name,
    (weekly_rate * 100) as weekly_percent,
    (monday_rate * 100) as monday_percent,
    (tuesday_rate * 100) as tuesday_percent,
    (wednesday_rate * 100) as wednesday_percent,
    (thursday_rate * 100) as thursday_percent,
    (friday_rate * 100) as friday_percent
FROM get_weekly_rates_for_admin_ui()
ORDER BY week_start_date DESC, group_name
LIMIT 20;
