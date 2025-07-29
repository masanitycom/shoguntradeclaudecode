-- 2月10日週の完全設定

-- 1. 型の不一致を修正するため、関数を再作成
DROP FUNCTION IF EXISTS show_available_groups();

CREATE OR REPLACE FUNCTION show_available_groups()
RETURNS TABLE(
    group_id UUID,
    group_name VARCHAR(50),  -- TEXTからVARCHAR(50)に変更
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
    LEFT JOIN nfts n ON n.daily_rate_limit = drg.daily_rate_limit
    GROUP BY drg.id, drg.group_name
    ORDER BY drg.group_name;
END;
$$ LANGUAGE plpgsql;

-- 2. get_weekly_rates_with_groups関数も型を修正
DROP FUNCTION IF EXISTS get_weekly_rates_with_groups();

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
    group_name VARCHAR(50),  -- TEXTからVARCHAR(50)に変更
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

-- 3. 権限再設定
GRANT EXECUTE ON FUNCTION show_available_groups() TO authenticated;
GRANT EXECUTE ON FUNCTION get_weekly_rates_with_groups() TO authenticated;

-- 4. 関数テスト
SELECT 'Testing fixed functions...' as status;

SELECT * FROM show_available_groups();

-- 5. 2月10日週の設定実行
SELECT 'Setting up February 10 week rates...' as status;

-- 各グループに週利設定
SELECT * FROM set_group_weekly_rate('2025-02-10'::DATE, '0.5%グループ', 1.5);
SELECT * FROM set_group_weekly_rate('2025-02-10'::DATE, '1.0%グループ', 2.0);
SELECT * FROM set_group_weekly_rate('2025-02-10'::DATE, '1.25%グループ', 2.3);
SELECT * FROM set_group_weekly_rate('2025-02-10'::DATE, '1.5%グループ', 2.6);
SELECT * FROM set_group_weekly_rate('2025-02-10'::DATE, '1.75%グループ', 2.9);
SELECT * FROM set_group_weekly_rate('2025-02-10'::DATE, '2.0%グループ', 3.2);

-- 6. 設定結果確認
SELECT 
    '✅ 最終設定確認' as section,
    drg.group_name,
    ROUND(gwr.weekly_rate * 100, 1) as weekly_rate_percent,
    ROUND(gwr.monday_rate * 100, 2) as monday_percent,
    ROUND(gwr.tuesday_rate * 100, 2) as tuesday_percent,
    ROUND(gwr.wednesday_rate * 100, 2) as wednesday_percent,
    ROUND(gwr.thursday_rate * 100, 2) as thursday_percent,
    ROUND(gwr.friday_rate * 100, 2) as friday_percent
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = '2025-02-10'::DATE
ORDER BY drg.group_name;

-- 7. 管理画面用関数テスト
SELECT 'Testing admin UI functions...' as status;

SELECT * FROM get_weekly_rates_with_groups() LIMIT 5;

SELECT '🎉 February 10 week setup completed successfully!' as status;
