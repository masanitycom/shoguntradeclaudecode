-- 日利計算結果の最終確認

-- 1. 今日の日利計算結果を確認
SELECT 
  'Today Daily Rewards Summary' as check_type,
  COUNT(*) as reward_entries,
  COUNT(DISTINCT user_id) as unique_users,
  SUM(reward_amount) as total_rewards,
  AVG(reward_amount) as avg_reward,
  MIN(reward_amount) as min_reward,
  MAX(reward_amount) as max_reward
FROM daily_rewards 
WHERE reward_date = CURRENT_DATE;

-- 2. ユーザー別の日利詳細
SELECT 
  'User Daily Rewards Detail' as check_type,
  u.name,
  u.email,
  COUNT(dr.id) as reward_count,
  SUM(dr.reward_amount) as total_daily_reward
FROM users u
LEFT JOIN daily_rewards dr ON u.id = dr.user_id AND dr.reward_date = CURRENT_DATE
GROUP BY u.id, u.name, u.email
ORDER BY total_daily_reward DESC NULLS LAST
LIMIT 20;

-- 3. NFT別の日利集計
SELECT 
  'NFT Daily Rewards Summary' as check_type,
  n.name as nft_name,
  n.daily_rate_limit,
  COUNT(dr.id) as reward_count,
  SUM(dr.reward_amount) as total_rewards,
  AVG(dr.reward_amount) as avg_reward
FROM nfts n
LEFT JOIN daily_rewards dr ON n.id = dr.nft_id AND dr.reward_date = CURRENT_DATE
WHERE n.is_active = true
GROUP BY n.id, n.name, n.daily_rate_limit
ORDER BY n.daily_rate_limit, total_rewards DESC NULLS LAST;

-- 4. 日利計算の詳細検証
WITH calculation_check AS (
  SELECT 
    dr.user_id,
    dr.nft_id,
    dr.reward_amount,
    dr.daily_rate,
    un.current_investment,
    n.name as nft_name,
    n.daily_rate_limit,
    un.current_investment * dr.daily_rate as expected_reward
  FROM daily_rewards dr
  JOIN user_nfts un ON dr.user_id = un.user_id AND dr.nft_id = un.nft_id
  JOIN nfts n ON dr.nft_id = n.id
  WHERE dr.reward_date = CURRENT_DATE
  LIMIT 10
)
SELECT 
  'Calculation Verification' as check_type,
  nft_name,
  current_investment,
  daily_rate,
  daily_rate_limit,
  reward_amount,
  expected_reward,
  CASE 
    WHEN ABS(reward_amount - expected_reward) < 0.01 THEN 'OK'
    ELSE 'ERROR'
  END as calculation_status
FROM calculation_check;

-- 5. システム全体の健康状態
SELECT 
  'System Health Summary' as check_type,
  (SELECT COUNT(*) FROM users WHERE is_active = true) as active_users,
  (SELECT COUNT(*) FROM user_nfts WHERE is_active = true AND current_investment > 0) as active_user_nfts,
  (SELECT COUNT(*) FROM nfts WHERE is_active = true) as active_nfts,
  (SELECT COUNT(*) FROM group_weekly_rates WHERE CURRENT_DATE BETWEEN week_start_date::DATE AND week_end_date::DATE) as current_week_rates,
  (SELECT COUNT(*) FROM daily_rewards WHERE reward_date = CURRENT_DATE) as today_rewards;
