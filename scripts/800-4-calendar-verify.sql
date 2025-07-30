-- 2025年2月のカレンダー確認
SELECT 'February 2025 Calendar' as info;
SELECT 
    date_val::date as date,
    EXTRACT(DOW FROM date_val) as dow,
    CASE EXTRACT(DOW FROM date_val)
        WHEN 0 THEN '日曜日'
        WHEN 1 THEN '月曜日'
        WHEN 2 THEN '火曜日'
        WHEN 3 THEN '水曜日'
        WHEN 4 THEN '木曜日'
        WHEN 5 THEN '金曜日'
        WHEN 6 THEN '土曜日'
    END as day_name
FROM generate_series('2025-02-01'::date, '2025-02-28'::date, '1 day'::interval) AS date_val
WHERE date_val::date BETWEEN '2025-02-08' AND '2025-02-17'
ORDER BY date_val;