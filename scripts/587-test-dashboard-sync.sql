-- ダッシュボード同期テスト

-- 1. ダッシュボード表示用データの取得テスト
SELECT 
  'Dashboard Data Test' as test_type,
  u.name,
  u.user_id,
  -- 総投資額（NFT価格の合計）
  COALESCE(SUM(n.price), 0) as total_investment,
  -- 総獲得額（user_nftsのtotal_earned合計）
  COALESCE(SUM(un.total_earned), 0) as total_earned_from_user_nfts,
  -- 保留中報酬（未申請の日利報酬）
  COALESCE((
    SELECT SUM(dr.reward_amount)
    FROM daily_rewards dr
    WHERE dr.user_id = u.id AND dr.is_claimed = false
  ), 0) as pending_rewards,
  -- NFT数
  COUNT(un.id) as nft_count
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
WHERE un.current_investment > 0
  AND n.price = 1000  -- $1,000のNFTを持つユーザー
GROUP BY u.id, u.name, u.user_id
ORDER BY total_earned_from_user_nfts DESC
LIMIT 5;

-- 2. 管理画面表示用データの取得テスト
SELECT 
  'Admin Display Test' as test_type,
  u.name,
  u.user_id,
  u.email,
  -- NFT情報
  n.name as nft_name,
  n.price as nft_price,
  un.current_investment,
  un.total_earned,
  un.is_active,
  -- 日利報酬統計
  (
    SELECT COUNT(*)
    FROM daily_rewards dr
    WHERE dr.user_id = u.id AND dr.user_nft_id = un.id
  ) as reward_count,
  (
    SELECT SUM(reward_amount)
    FROM daily_rewards dr
    WHERE dr.user_id = u.id AND dr.user_nft_id = un.id
  ) as total_rewards_calculated
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
WHERE n.price = 1000
  AND un.current_investment > 0
ORDER BY un.total_earned DESC
LIMIT 5;

-- 3. 最新の日利計算状況
SELECT 
  'Latest Daily Calculation' as test_type,
  dr.reward_date,
  COUNT(*) as users_calculated,
  SUM(dr.reward_amount) as total_amount,
  AVG(dr.reward_amount) as avg_amount,
  MIN(dr.reward_amount) as min_amount,
  MAX(dr.reward_amount) as max_amount
FROM daily_rewards dr
WHERE dr.reward_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY dr.reward_date
ORDER BY dr.reward_date DESC;
