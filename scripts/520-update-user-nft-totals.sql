-- user_nftsテーブルのtotal_earnedを更新

-- 1. 各ユーザーNFTのtotal_earnedを日利報酬から計算して更新
UPDATE user_nfts 
SET 
  total_earned = COALESCE((
    SELECT SUM(dr.reward_amount)
    FROM daily_rewards dr
    WHERE dr.user_id = user_nfts.user_id 
      AND dr.nft_id = user_nfts.nft_id
  ), 0),
  updated_at = NOW()
WHERE EXISTS (
  SELECT 1 FROM daily_rewards dr
  WHERE dr.user_id = user_nfts.user_id 
    AND dr.nft_id = user_nfts.nft_id
);

-- 2. 300%達成したNFTを非アクティブ化
UPDATE user_nfts 
SET 
  is_active = false,
  completion_date = CURRENT_DATE,
  updated_at = NOW()
WHERE total_earned >= max_earning 
  AND is_active = true
  AND max_earning > 0;

-- 3. 更新結果を確認
SELECT 
  'User NFT Update Results' as check_type,
  COUNT(*) as total_user_nfts,
  COUNT(CASE WHEN total_earned > 0 THEN 1 END) as nfts_with_earnings,
  COUNT(CASE WHEN is_active = false AND completion_date IS NOT NULL THEN 1 END) as completed_nfts,
  SUM(total_earned) as total_all_earnings
FROM user_nfts;

-- 4. 上位ユーザーの更新状況
SELECT 
  'Top Users After Update' as check_type,
  COALESCE(u.name, u.email) as user_name,
  COUNT(un.id) as nft_count,
  SUM(un.current_investment) as total_investment,
  SUM(un.total_earned) as total_earned,
  COUNT(CASE WHEN un.is_active = false THEN 1 END) as completed_nfts
FROM users u
JOIN user_nfts un ON u.id = un.user_id
WHERE un.current_investment > 0
GROUP BY u.id, u.name, u.email
ORDER BY total_earned DESC
LIMIT 10;
