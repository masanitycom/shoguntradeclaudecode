-- 正しい日付が設定されているかを詳細確認

-- 1. 週利設定の日付一覧
SELECT 
    '📅 設定された週の一覧' as section,
    week_start_date as monday,
    (week_start_date + INTERVAL '6 days')::DATE as sunday,
    COUNT(*) as groups,
    CASE 
        WHEN week_start_date <= CURRENT_DATE AND (week_start_date + INTERVAL '6 days')::DATE >= CURRENT_DATE 
        THEN '今週'
        WHEN week_start_date > CURRENT_DATE 
        THEN '未来'
        ELSE '過去'
    END as period_type
FROM group_weekly_rates
GROUP BY week_start_date
ORDER BY week_start_date DESC;

-- 2. 各週の詳細設定
SELECT 
    '📋 週利設定詳細（正しい日付）' as section,
    gwr.week_start_date,
    drg.group_name,
    (gwr.weekly_rate * 100) as weekly_percent,
    (gwr.monday_rate * 100) as mon,
    (gwr.tuesday_rate * 100) as tue,
    (gwr.wednesday_rate * 100) as wed,
    (gwr.thursday_rate * 100) as thu,
    (gwr.friday_rate * 100) as fri
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date >= CURRENT_DATE - INTERVAL '4 weeks'
ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit
LIMIT 30;
