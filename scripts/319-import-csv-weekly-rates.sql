-- CSVデータに基づく週利設定のためのSQL
-- 正しい基準日: 2025-02-10（第1週の月曜日）

-- 週利データの確認
SELECT 
  week_number,
  COUNT(*) as record_count,
  AVG(weekly_rate) as avg_rate,
  MAX(weekly_rate) as max_rate,
  MIN(week_start_date) as week_start,
  MAX(week_end_date) as week_end
FROM nft_weekly_rates 
WHERE week_number BETWEEN 2 AND 19
GROUP BY week_number
ORDER BY week_number;

-- 正しい日付範囲の確認
WITH correct_dates AS (
  SELECT 
    generate_series(2, 19) as week_number,
    ('2025-02-10'::date + (generate_series(2, 19) - 1) * interval '7 days')::date as week_start_date,
    ('2025-02-10'::date + (generate_series(2, 19) - 1) * interval '7 days' + interval '4 days')::date as week_end_date
)
SELECT 
  week_number,
  week_start_date,
  week_end_date,
  to_char(week_start_date, 'MM/DD') || '～' || to_char(week_end_date, 'MM/DD') as date_range
FROM correct_dates
ORDER BY week_number;

-- 第2週が2025/2/17から始まることを確認
SELECT 
  '第2週の開始日' as description,
  ('2025-02-10'::date + interval '7 days')::date as calculated_date,
  '2025-02-17'::date as expected_date,
  CASE 
    WHEN ('2025-02-10'::date + interval '7 days')::date = '2025-02-17'::date 
    THEN '✅ 正しい' 
    ELSE '❌ 間違い' 
  END as status;
