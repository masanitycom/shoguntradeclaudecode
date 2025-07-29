-- ユーザーダッシュボードデータの検証

-- 1. 特定ユーザーのダッシュボードデータをテスト
SELECT 
  'Dashboard Data Test' as test_type,
  u.id as user_id,
  COALESCE(u.name, u.email) as user_name,
  dd.*
FROM users u
CROSS JOIN LATERAL get_user_dashboard_data(u.id) dd
WHERE EXISTS (
  SELECT 1 FROM user_nfts un 
  WHERE un.user_id = u.id AND un.is_active = true
)
ORDER BY dd.pending_rewards DESC
LIMIT 10;

-- 2. ユーザー報酬サマリーをテスト
SELECT 
  'Reward Summary Test' as test_type,
  u.id as user_id,
  COALESCE(u.name, u.email) as user_name,
  rs.*
FROM users u
CROSS JOIN LATERAL get_user_reward_summary(u.id) rs
WHERE EXISTS (
  SELECT 1 FROM user_nfts un 
  WHERE un.user_id = u.id AND un.is_active = true
)
ORDER BY rs.pending_rewards DESC
LIMIT 10;

-- 3. 申請可能報酬をテスト
SELECT 
  'Claimable Rewards Test' as test_type,
  u.id as user_id,
  COALESCE(u.name, u.email) as user_name,
  cr.*
FROM users u
CROSS JOIN LATERAL get_user_claimable_rewards(u.id) cr
WHERE EXISTS (
  SELECT 1 FROM daily_rewards dr 
  WHERE dr.user_id = u.id AND dr.is_claimed = false
)
ORDER BY cr.total_claimable DESC
LIMIT 10;

-- 4. 日利履歴をテスト（上位ユーザー）
SELECT 
  'Daily Rewards History Test' as test_type,
  u.id as user_id,
  COALESCE(u.name, u.email) as user_name,
  drh.*
FROM users u
CROSS JOIN LATERAL get_user_daily_rewards_history(u.id, 5) drh
WHERE EXISTS (
  SELECT 1 FROM daily_rewards dr 
  WHERE dr.user_id = u.id
)
ORDER BY u.id, drh.reward_date DESC
LIMIT 20;

-- 5. システム全体の統計
SELECT 
  'System Statistics' as stats_type,
  'Total Users with Rewards' as metric,
  COUNT(DISTINCT dr.user_id) as value
FROM daily_rewards dr

UNION ALL

SELECT 
  'System Statistics' as stats_type,
  'Total Pending Rewards' as metric,
  COALESCE(SUM(dr.reward_amount), 0) as value
FROM daily_rewards dr
WHERE dr.is_claimed = false

UNION ALL

SELECT 
  'System Statistics' as stats_type,
  'Average Pending per User' as metric,
  CASE 
    WHEN COUNT(DISTINCT dr.user_id) > 0 
    THEN COALESCE(SUM(dr.reward_amount), 0) / COUNT(DISTINCT dr.user_id)
    ELSE 0
  END as value
FROM daily_rewards dr
WHERE dr.is_claimed = false;

-- 6. 最も報酬の多いユーザー詳細
WITH top_users AS (
  SELECT 
    dr.user_id,
    SUM(dr.reward_amount) as total_pending
  FROM daily_rewards dr
  WHERE dr.is_claimed = false
  GROUP BY dr.user_id
  ORDER BY total_pending DESC
  LIMIT 5
)
SELECT 
  'Top User Details' as detail_type,
  COALESCE(u.name, u.email) as user_name,
  tu.total_pending,
  COUNT(un.id) as nft_count,
  SUM(un.current_investment) as total_investment,
  SUM(un.total_earned) as total_earned
FROM top_users tu
JOIN users u ON tu.user_id = u.id
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
GROUP BY u.id, u.name, u.email, tu.total_pending
ORDER BY tu.total_pending DESC;

-- 7. 関数の動作確認
SELECT 'Function Test Complete' as status;
