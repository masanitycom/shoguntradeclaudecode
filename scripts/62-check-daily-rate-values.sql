-- 日利上限の実際の値を確認
SELECT 
  name,
  price,
  daily_rate_limit,
  daily_rate_limit * 100 as "表示される値（現在）",
  CASE 
    WHEN daily_rate_limit >= 1 THEN daily_rate_limit
    ELSE daily_rate_limit * 100
  END as "正しい表示値"
FROM nfts 
ORDER BY price 
LIMIT 10;

-- 日利上限の統計
SELECT 
  MIN(daily_rate_limit) as "最小値",
  MAX(daily_rate_limit) as "最大値",
  AVG(daily_rate_limit) as "平均値",
  COUNT(*) as "総数"
FROM nfts;
