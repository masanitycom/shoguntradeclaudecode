-- 日利計算システムの動作確認

-- 1. 今週の週利設定確認
SELECT 
  'Weekly Rates Check' as check_type,
  gwr.week_start_date,
  gwr.week_end_date,
  drg.group_name,
  gwr.weekly_rate,
  gwr.monday_rate,
  gwr.tuesday_rate,
  gwr.wednesday_rate,
  gwr.thursday_rate,
  gwr.friday_rate
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE CURRENT_DATE BETWEEN gwr.week_start_date::DATE AND gwr.week_end_date::DATE
ORDER BY drg.daily_rate_limit;

-- 2. アクティブなuser_nfts確認
SELECT 
  'Active User NFTs' as check_type,
  COUNT(*) as total_count,
  COUNT(CASE WHEN current_investment > 0 THEN 1 END) as with_investment,
  SUM(current_investment) as total_investment
FROM user_nfts 
WHERE is_active = true;

-- 3. NFTとグループの関連確認
SELECT 
  'NFT Group Mapping' as check_type,
  n.name as nft_name,
  n.daily_rate_limit,
  drg.group_name,
  COUNT(un.id) as user_count
FROM nfts n
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
LEFT JOIN user_nfts un ON n.id = un.nft_id AND un.is_active = true
WHERE n.is_active = true
GROUP BY n.id, n.name, n.daily_rate_limit, drg.group_name
ORDER BY n.daily_rate_limit;

-- 4. 今日の日利計算結果確認
SELECT 
  'Today Calculation Results' as check_type,
  dr.reward_date,
  COUNT(*) as reward_count,
  SUM(dr.reward_amount) as total_rewards,
  AVG(dr.reward_amount) as avg_reward,
  MIN(dr.reward_amount) as min_reward,
  MAX(dr.reward_amount) as max_reward
FROM daily_rewards dr
WHERE dr.reward_date = CURRENT_DATE
GROUP BY dr.reward_date;

-- 5. ユーザー別の詳細確認（上位10名）
SELECT 
  'Top Users Today' as check_type,
  u.name,
  u.email,
  COUNT(dr.id) as nft_count,
  SUM(dr.reward_amount) as total_reward,
  SUM(un.current_investment) as total_investment
FROM users u
JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
LEFT JOIN daily_rewards dr ON u.id = dr.user_id AND dr.reward_date = CURRENT_DATE
WHERE u.is_admin = false
GROUP BY u.id, u.name, u.email
HAVING SUM(dr.reward_amount) > 0
ORDER BY total_reward DESC
LIMIT 10;
