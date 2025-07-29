-- ユーザー計算問題の詳細調査

-- 1. 具体的なユーザーデータを確認（投資額$1,000のユーザー）
SELECT 
  'User NFT Data Analysis' as check_type,
  u.name,
  u.user_id,
  un.id as user_nft_id,
  n.name as nft_name,
  n.price as nft_price,
  un.current_investment,
  un.total_earned,
  un.max_earning,
  un.is_active,
  un.created_at as nft_acquired_date,
  un.completion_date
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
WHERE n.price = 1000
  AND un.current_investment > 0
ORDER BY un.total_earned DESC
LIMIT 10;

-- 2. 日利報酬の計算履歴を確認
SELECT 
  'Daily Rewards History' as check_type,
  u.name,
  u.user_id,
  COUNT(dr.id) as reward_count,
  MIN(dr.reward_date) as first_reward_date,
  MAX(dr.reward_date) as last_reward_date,
  SUM(dr.reward_amount) as total_daily_rewards,
  AVG(dr.reward_amount) as avg_daily_reward,
  COUNT(CASE WHEN dr.is_claimed THEN 1 END) as claimed_count,
  COUNT(CASE WHEN NOT dr.is_claimed THEN 1 END) as pending_count
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
LEFT JOIN daily_rewards dr ON dr.user_id = u.id AND dr.nft_id = n.id
WHERE n.price = 1000
  AND un.current_investment > 0
GROUP BY u.id, u.name, u.user_id
ORDER BY total_daily_rewards DESC;

-- 3. 最近の週利設定を確認
SELECT 
  'Recent Weekly Rates' as check_type,
  gwr.week_start_date,
  gwr.week_end_date,
  gwr.weekly_rate,
  gwr.monday_rate,
  gwr.tuesday_rate,
  gwr.wednesday_rate,
  gwr.thursday_rate,
  gwr.friday_rate,
  drg.group_name,
  gwr.distribution_method
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date >= CURRENT_DATE - INTERVAL '2 weeks'
ORDER BY gwr.week_start_date DESC, drg.group_name;

-- 4. 特定ユーザーの詳細計算チェック（$112.00の収益を持つユーザー）
SELECT 
  'Specific User Analysis' as check_type,
  u.name,
  u.user_id,
  un.total_earned,
  COUNT(dr.id) as daily_reward_records,
  SUM(dr.reward_amount) as calculated_total,
  un.total_earned - COALESCE(SUM(dr.reward_amount), 0) as discrepancy,
  CASE 
    WHEN ABS(un.total_earned - COALESCE(SUM(dr.reward_amount), 0)) < 0.01 THEN '✅ 一致'
    ELSE '❌ 不一致'
  END as status
FROM users u
JOIN user_nfts un ON u.id = un.user_id
LEFT JOIN daily_rewards dr ON dr.user_id = u.id AND dr.user_nft_id = un.id
WHERE un.total_earned BETWEEN 111.00 AND 113.00
GROUP BY u.id, u.name, u.user_id, un.id, un.total_earned
ORDER BY discrepancy DESC;

-- 5. 日利計算関数の最後の実行状況
SELECT 
  'Daily Calculation Status' as check_type,
  MAX(dr.created_at) as last_calculation_time,
  MAX(dr.reward_date) as last_reward_date,
  COUNT(DISTINCT dr.reward_date) as calculation_days,
  COUNT(dr.id) as total_rewards_calculated,
  SUM(dr.reward_amount) as total_amount_calculated
FROM daily_rewards dr
WHERE dr.created_at >= CURRENT_DATE - INTERVAL '7 days';

-- 6. user_nftsとdaily_rewardsの同期状況
SELECT 
  'Sync Status Check' as check_type,
  COUNT(DISTINCT un.id) as total_user_nfts,
  COUNT(DISTINCT CASE WHEN dr.id IS NOT NULL THEN un.id END) as nfts_with_rewards,
  COUNT(DISTINCT CASE WHEN un.total_earned > 0 THEN un.id END) as nfts_with_earnings,
  COUNT(DISTINCT CASE WHEN un.total_earned > 0 AND dr.id IS NULL THEN un.id END) as earnings_without_rewards
FROM user_nfts un
LEFT JOIN daily_rewards dr ON dr.user_id = un.user_id AND dr.user_nft_id = un.id
WHERE un.current_investment > 0;
