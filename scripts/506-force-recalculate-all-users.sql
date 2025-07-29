-- 全ユーザーの日利を強制再計算

-- 1. 今日の既存の日利記録を削除
DELETE FROM daily_rewards WHERE reward_date = CURRENT_DATE;

-- 2. 強制的に全ユーザーの日利を再計算
SELECT * FROM calculate_daily_rewards_batch(CURRENT_DATE);

-- 3. 結果の詳細確認
WITH user_rewards AS (
  SELECT 
    u.id,
    u.name,
    u.email,
    COUNT(dr.id) as reward_entries,
    COALESCE(SUM(dr.reward_amount), 0) as daily_reward,
    COALESCE(SUM(un.current_investment), 0) as total_investment
  FROM users u
  LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
  LEFT JOIN daily_rewards dr ON u.id = dr.user_id AND dr.reward_date = CURRENT_DATE
  WHERE u.is_admin = false
  GROUP BY u.id, u.name, u.email
)
SELECT 
  'User Calculation Results' as result_type,
  name,
  email,
  reward_entries,
  daily_reward,
  total_investment,
  CASE 
    WHEN total_investment > 0 AND daily_reward > 0 THEN 
      ROUND((daily_reward / total_investment * 100)::NUMERIC, 4) || '%'
    ELSE '0%'
  END as daily_rate_achieved
FROM user_rewards
ORDER BY daily_reward DESC;

-- 4. システム全体のサマリー
SELECT 
  'System Summary' as summary_type,
  COUNT(DISTINCT dr.user_id) as users_with_rewards,
  COUNT(dr.id) as total_reward_entries,
  SUM(dr.reward_amount) as total_daily_rewards,
  AVG(dr.reward_amount) as average_reward_per_nft,
  MIN(dr.reward_amount) as min_reward,
  MAX(dr.reward_amount) as max_reward
FROM daily_rewards dr
WHERE dr.reward_date = CURRENT_DATE;
