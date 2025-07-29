-- CSVデータ構造の確認と分析

-- 1. 提供されたCSVデータの分析
SELECT '📋 提供されたCSVデータ分析' as analysis_type;

-- CSVデータから読み取れる情報:
-- 前半: 2週目3週目4週目5週目6週目7週目8週目9週目10週目11週目12週目13週目14週目15週目16週目17週目18週目19週目20週目
-- 後半: 2025/2/10~14 2025/2/17~21 2025/2/24~28 2025/3/3~7 2025/3/10~14 2025/3/17~21 2025/3/24~28 2025/3/31~4/4 2025/4/7~4/11 2025/4/14~4/18 2025/4/21~4/25 2025/5/7~5/9 2025/5/12~5/16 2025/5/19~5/23 2025/5/26~5/30 2025/6/2~6/6 2025/6/9~6/13 2025/6/16~6/20 2025/6/23~6/27

-- 2. 日付範囲と週番号の対応表
WITH csv_date_mapping AS (
  SELECT week_number, date_range FROM (VALUES
    (2, '2025/2/10~14'),
    (3, '2025/2/17~21'),
    (4, '2025/2/24~28'),
    (5, '2025/3/3~7'),
    (6, '2025/3/10~14'),
    (7, '2025/3/17~21'),
    (8, '2025/3/24~28'),
    (9, '2025/3/31~4/4'),
    (10, '2025/4/7~4/11'),
    (11, '2025/4/14~4/18'),
    (12, '2025/4/21~4/25'),
    (13, '2025/5/7~5/9'),
    (14, '2025/5/12~5/16'),
    (15, '2025/5/19~5/23'),
    (16, '2025/5/26~5/30'),
    (17, '2025/6/2~6/6'),
    (18, '2025/6/9~6/13'),
    (19, '2025/6/16~6/20'),
    (20, '2025/6/23~6/27')
  ) AS t(week_number, date_range)
)
SELECT 
  '📅 CSV日付マッピング' as info,
  week_number,
  date_range as csv_date_range,
  ('2025-01-06'::date + (week_number - 1) * interval '7 days')::date as correct_start_date,
  to_char(('2025-01-06'::date + (week_number - 1) * interval '7 days'), 'YYYY/MM/DD') as correct_format
FROM csv_date_mapping
ORDER BY week_number;

-- 3. 日付の整合性チェック
WITH csv_dates AS (
  SELECT week_number, date_range FROM (VALUES
    (2, '2025/2/10~14'),
    (3, '2025/2/17~21'),
    (4, '2025/2/24~28'),
    (5, '2025/3/3~7'),
    (6, '2025/3/10~14'),
    (7, '2025/3/17~21'),
    (8, '2025/3/24~28'),
    (9, '2025/3/31~4/4'),
    (10, '2025/4/7~4/11'),
    (11, '2025/4/14~4/18'),
    (12, '2025/4/21~4/25'),
    (13, '2025/5/7~5/9'),
    (14, '2025/5/12~5/16'),
    (15, '2025/5/19~5/23'),
    (16, '2025/5/26~5/30'),
    (17, '2025/6/2~6/6'),
    (18, '2025/6/9~6/13'),
    (19, '2025/6/16~6/20'),
    (20, '2025/6/23~6/27')
  ) AS t(week_number, date_range)
)
SELECT 
  '🔍 日付整合性チェック' as info,
  cd.week_number,
  cd.date_range,
  ('2025-01-06'::date + (cd.week_number - 1) * interval '7 days')::date as system_start,
  CASE 
    WHEN cd.date_range LIKE '2025/2/10%' AND cd.week_number = 2 THEN '❌ 不一致'
    WHEN cd.date_range LIKE '2025/2/17%' AND cd.week_number = 3 THEN '❌ 不一致'
    ELSE '要確認'
  END as status
FROM csv_dates cd
ORDER BY cd.week_number;

-- 4. 現在のDB状況
SELECT 
  '📊 現在のDB週利設定' as info,
  week_number,
  COUNT(*) as nft_count,
  MIN(weekly_rate) as min_rate,
  MAX(weekly_rate) as max_rate,
  MIN(week_start_date) as start_date
FROM nft_weekly_rates 
WHERE week_number >= 2
GROUP BY week_number
ORDER BY week_number;

-- 5. 不足情報の特定
SELECT '❓ 不足している情報' as info;
SELECT '1. 各週の実際の週利パーセンテージ' as missing_data;
SELECT '2. NFT別の設定値' as missing_data;
SELECT '3. 完全なCSVファイルの内容' as missing_data;

-- 6. 推奨アクション
SELECT '💡 推奨アクション' as recommendation;
SELECT '1. 完全なCSVファイルを確認してください' as action;
SELECT '2. 週利パーセンテージデータの場所を特定してください' as action;
SELECT '3. 正しいデータ形式で再提供してください' as action;

SELECT '⚠️ 現在のCSVデータでは週利パーセンテージが不明です' as warning;
