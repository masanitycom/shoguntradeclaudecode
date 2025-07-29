-- 過去の週利データを復元
-- 2024年1月から現在まで週利2.6%で復元

-- 1. 現在のデータ状況を確認
SELECT 
    'Current Data Status' as check_type,
    COUNT(*) as total_records,
    MIN(week_start_date) as earliest_week,
    MAX(week_start_date) as latest_week
FROM group_weekly_rates;

-- 2. 2024年1月から現在まで週利2.6%で一括設定
SELECT * FROM bulk_set_historical_rates(
    '2024-01-01'::DATE,
    CURRENT_DATE,
    2.6,
    'random'
);

-- 3. 復元結果を確認
SELECT 
    'Restoration Result' as check_type,
    COUNT(*) as total_records,
    COUNT(DISTINCT week_start_date) as total_weeks,
    COUNT(DISTINCT group_id) as total_groups,
    MIN(week_start_date) as earliest_week,
    MAX(week_start_date) as latest_week
FROM group_weekly_rates;

-- 4. グループ別の設定状況を確認
SELECT 
    drg.group_name,
    COUNT(*) as weeks_configured,
    MIN(gwr.week_start_date) as first_week,
    MAX(gwr.week_start_date) as last_week,
    ROUND(AVG(gwr.weekly_rate * 100), 2) as avg_weekly_rate_percent
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
GROUP BY drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;

-- 5. 最新の週利設定を表示
SELECT 
    gwr.week_start_date,
    drg.group_name,
    ROUND(gwr.weekly_rate * 100, 2) as weekly_rate_percent,
    ROUND(gwr.monday_rate * 100, 2) as monday_percent,
    ROUND(gwr.tuesday_rate * 100, 2) as tuesday_percent,
    ROUND(gwr.wednesday_rate * 100, 2) as wednesday_percent,
    ROUND(gwr.thursday_rate * 100, 2) as thursday_percent,
    ROUND(gwr.friday_rate * 100, 2) as friday_percent,
    gwr.distribution_method
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date >= CURRENT_DATE - INTERVAL '14 days'
ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit;

-- 完了メッセージ
SELECT 'Historical weekly rates data restoration completed' as status;
