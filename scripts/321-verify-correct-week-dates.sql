-- 正しい週の日付を確認
-- 第1週の月曜日: 2025-01-06
-- 第2週の月曜日: 2025-01-13 (2025/1/13~1/17)

WITH week_dates AS (
  SELECT 
    generate_series(1, 25) as week_number,
    ('2025-01-06'::date + (generate_series(1, 25) - 1) * interval '7 days')::date as week_start_date,
    ('2025-01-06'::date + (generate_series(1, 25) - 1) * interval '7 days' + interval '4 days')::date as week_end_date
)
SELECT 
  week_number,
  week_start_date,
  week_end_date,
  to_char(week_start_date, 'MM/DD') || '～' || to_char(week_end_date, 'MM/DD') as date_range,
  to_char(week_start_date, 'Day') as start_day_name
FROM week_dates
WHERE week_number BETWEEN 1 AND 25
ORDER BY week_number;

-- 特に第2週の確認
SELECT 
  '第2週の確認' as description,
  ('2025-01-06'::date + interval '7 days')::date as calculated_start,
  ('2025-01-06'::date + interval '11 days')::date as calculated_end,
  to_char(('2025-01-06'::date + interval '7 days')::date, 'MM/DD') || '～' || 
  to_char(('2025-01-06'::date + interval '11 days')::date, 'MM/DD') as date_range;
