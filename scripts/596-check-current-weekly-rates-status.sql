-- 現在の週利設定状況を確認

-- 1. 利用可能なグループを表示
SELECT 
    'Available Groups' as info,
    group_name,
    daily_rate_limit,
    ROUND(daily_rate_limit * 100, 2) || '%' as daily_rate_percent
FROM daily_rate_groups 
ORDER BY daily_rate_limit;

-- 2. 設定済み週利を確認
SELECT 
    'Configured Weekly Rates' as info,
    gwr.week_start_date,
    gwr.week_end_date,
    drg.group_name,
    ROUND(gwr.weekly_rate * 100, 2) || '%' as weekly_rate_percent,
    ROUND(gwr.monday_rate * 100, 2) || '%' as monday_percent,
    ROUND(gwr.tuesday_rate * 100, 2) || '%' as tuesday_percent,
    ROUND(gwr.wednesday_rate * 100, 2) || '%' as wednesday_percent,
    ROUND(gwr.thursday_rate * 100, 2) || '%' as thursday_percent,
    ROUND(gwr.friday_rate * 100, 2) || '%' as friday_percent
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit;

-- 3. 未設定の週を確認
SELECT 
    'Missing Weeks' as info,
    'No configured weeks found' as message
WHERE NOT EXISTS (SELECT 1 FROM group_weekly_rates);
