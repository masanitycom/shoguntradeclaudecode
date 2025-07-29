-- ユーザーダッシュボード同期の最終確認

-- 1. 投資額$1,000のユーザーの詳細状況
SELECT 
  'Investment $1000 Users Detail' as analysis_type,
  u.name,
  u.user_id,
  n.name as nft_name,
  n.price as nft_price,
  un.current_investment,
  un.total_earned as user_nft_total,
  (
    SELECT SUM(dr.reward_amount)
    FROM daily_rewards dr
    WHERE dr.user_id = u.id AND dr.user_nft_id = un.id
  ) as daily_rewards_sum,
  (
    SELECT COUNT(*)
    FROM daily_rewards dr
    WHERE dr.user_id = u.id AND dr.user_nft_id = un.id
  ) as reward_days_count,
  (
    SELECT MAX(dr.reward_date)
    FROM daily_rewards dr
    WHERE dr.user_id = u.id AND dr.user_nft_id = un.id
  ) as last_reward_date,
  un.is_active,
  un.created_at as nft_acquired_date
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
WHERE n.price = 1000
  AND un.current_investment > 0
ORDER BY un.total_earned DESC;

-- 2. ダッシュボード関数のテスト実行
SELECT 
  'Dashboard Function Test' as test_type,
  u.name,
  u.user_id,
  (SELECT get_user_total_investment(u.id)) as calculated_investment,
  (SELECT get_user_total_earned(u.id)) as calculated_earned,
  (SELECT total_pending FROM get_user_pending_rewards(u.id)) as calculated_pending
FROM users u
WHERE EXISTS (
  SELECT 1 FROM user_nfts un 
  JOIN nfts n ON un.nft_id = n.id
  WHERE un.user_id = u.id AND n.price = 1000
)
LIMIT 5;

-- 3. 管理画面とダッシュボードの数値比較
WITH admin_data AS (
  SELECT 
    u.id as user_id,
    u.name,
    SUM(n.price) as admin_investment,
    SUM(un.total_earned) as admin_earned
  FROM users u
  JOIN user_nfts un ON u.id = un.user_id
  JOIN nfts n ON un.nft_id = n.id
  WHERE un.current_investment > 0
  GROUP BY u.id, u.name
),
dashboard_data AS (
  SELECT 
    u.id as user_id,
    u.name,
    (SELECT get_user_total_investment(u.id)) as dashboard_investment,
    (SELECT get_user_total_earned(u.id)) as dashboard_earned
  FROM users u
  WHERE EXISTS (
    SELECT 1 FROM user_nfts un 
    WHERE un.user_id = u.id AND un.current_investment > 0
  )
)
SELECT 
  'Admin vs Dashboard Comparison' as comparison_type,
  a.name,
  a.admin_investment,
  d.dashboard_investment,
  a.admin_earned,
  d.dashboard_earned,
  CASE 
    WHEN a.admin_investment = d.dashboard_investment THEN '✅'
    ELSE '❌'
  END as investment_match,
  CASE 
    WHEN ABS(a.admin_earned - d.dashboard_earned) < 0.01 THEN '✅'
    ELSE '❌'
  END as earned_match
FROM admin_data a
JOIN dashboard_data d ON a.user_id = d.user_id
WHERE a.admin_investment = 1000  -- $1,000投資のユーザー
ORDER BY a.admin_earned DESC;
