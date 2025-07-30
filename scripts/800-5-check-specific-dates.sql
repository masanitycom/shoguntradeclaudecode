-- 問題の日付を確認
SELECT 'Specific dates check' as info;
WITH dates_to_check AS (
    SELECT unnest(ARRAY[
        '2025-02-09'::date,
        '2025-02-10'::date,
        '2025-02-16'::date,
        '2025-02-17'::date,
        '2025-05-25'::date,
        '2025-05-26'::date,
        '2025-06-08'::date,
        '2025-06-09'::date
    ]) as check_date
)
SELECT 
    check_date,
    TO_CHAR(check_date, 'YYYY-MM-DD Day') as formatted_date,
    EXTRACT(DOW FROM check_date) as dow,
    CASE EXTRACT(DOW FROM check_date)
        WHEN 0 THEN '日曜日'
        WHEN 1 THEN '月曜日'
        WHEN 2 THEN '火曜日'
        WHEN 3 THEN '水曜日'
        WHEN 4 THEN '木曜日'
        WHEN 5 THEN '金曜日'
        WHEN 6 THEN '土曜日'
    END as japanese_day
FROM dates_to_check
ORDER BY check_date;