-- 週利データインポート用SQL（完全なデータが提供された後に使用）

-- 現在の状況: CSVデータに週利パーセンテージが含まれていない
-- このスクリプトは完全なデータが提供された後に実行してください

-- 1. 現在の設定状況を確認
SELECT 
  '📊 現在の設定確認' as status,
  week_number,
  COUNT(*) as nft_count,
  ROUND(AVG(weekly_rate), 2) as avg_rate
FROM nft_weekly_rates 
WHERE week_number >= 2
GROUP BY week_number
ORDER BY week_number;

-- 2. 不足している週を特定
WITH expected_weeks AS (
  SELECT generate_series(2, 20) as week_number
),
existing_weeks AS (
  SELECT DISTINCT week_number 
  FROM nft_weekly_rates 
  WHERE week_number BETWEEN 2 AND 20
)
SELECT 
  '❌ 不足している週' as status,
  ew.week_number,
  ('2025-01-06'::date + (ew.week_number - 1) * interval '7 days')::date as week_start_date
FROM expected_weeks ew
LEFT JOIN existing_weeks ex ON ew.week_number = ex.week_number
WHERE ex.week_number IS NULL
ORDER BY ew.week_number;

-- 3. 対象NFT確認
SELECT 
  '🎯 対象NFT' as status,
  id, 
  name, 
  daily_rate_limit,
  is_active
FROM nfts 
WHERE is_active = true
ORDER BY name;

-- 4. インポート準備状況
SELECT 
  '⚠️ インポート準備状況' as status,
  'CSVデータに週利パーセンテージが不足しています' as message,
  '完全なデータが必要です' as requirement;

-- 5. サンプルデータ構造（参考）
SELECT '📋 必要なデータ構造（例）' as example;

-- 例: 以下のような形式のデータが必要
-- week_number | nft_name | weekly_rate
-- 2 | SHOGUN NFT 100 | 1.46
-- 2 | SHOGUN NFT 200 | 1.46
-- 3 | SHOGUN NFT 100 | 1.37
-- 3 | SHOGUN NFT 200 | 1.37

-- 6. 次のステップ
SELECT '🚀 次のステップ' as next_step;
SELECT '1. 完全なCSVファイルを取得' as step;
SELECT '2. 週利パーセンテージデータを確認' as step;
SELECT '3. 正しい形式でデータを再提供' as step;
SELECT '4. このスクリプトを再実行' as step;

-- 7. 一時的なテストデータ作成（デモ用）
-- 実際のデータが提供されるまでの一時的な処理
DO $$
BEGIN
  -- 実際のデータが提供されるまでは実行しない
  RAISE NOTICE '⚠️ 実際の週利データが必要です';
  RAISE NOTICE '現在のCSVデータでは週利パーセンテージが不明です';
END $$;
