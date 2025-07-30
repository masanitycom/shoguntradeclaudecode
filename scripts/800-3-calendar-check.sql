-- カレンダー確認用：特定日付の曜日チェック
SELECT 'Calendar verification for 2025' as info;
SELECT 
    date_val::date as calendar_date,
    EXTRACT(DOW FROM date_val) as dow,
    CASE EXTRACT(DOW FROM date_val)
        WHEN 0 THEN '日曜日' WHEN 1 THEN '月曜日' WHEN 2 THEN '火曜日'
        WHEN 3 THEN '水曜日' WHEN 4 THEN '木曜日' WHEN 5 THEN '金曜日' 
        WHEN 6 THEN '土曜日'
    END as day_name
FROM (VALUES 
    ('2025-05-25'::date),
    ('2025-05-26'::date),
    ('2025-06-08'::date),
    ('2025-06-09'::date),
    ('2025-07-28'::date),
    ('2025-07-29'::date)
) AS dates(date_val);