-- 日利報酬システム実装準備状況の確認

-- 1. daily_rewardsテーブルの構造確認
SELECT 'daily_rewards table structure' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
ORDER BY ordinal_position;

-- 2. user_nftsテーブルのアクティブNFT確認
SELECT 'Active user NFTs' as info;
SELECT 
  un.user_id,
  u.name,
  un.nft_id,
  n.name as nft_name,
  n.price,
  n.daily_rate_limit,
  un.current_investment,
  un.total_earned,
  un.max_earning,
  un.is_active
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true
ORDER BY u.name;

-- 3. weekly_profitsテーブルの最新週利設定
SELECT 'Latest weekly profits' as info;
SELECT 
  week_start_date,
  total_profit,
  tenka_bonus_pool,
  created_at
FROM weekly_profits
ORDER BY week_start_date DESC
LIMIT 3;

-- 4. nftsテーブルの日利上限設定
SELECT 'NFTs daily rate limits' as info;
SELECT 
  id,
  name,
  price,
  daily_rate_limit,
  is_special,
  is_active
FROM nfts
WHERE is_active = true
ORDER BY is_special, price;

-- 5. 既存のdaily_rewardsレコード確認
SELECT 'Existing daily rewards' as info;
SELECT 
  COUNT(*) as total_records,
  MIN(reward_date) as earliest_date,
  MAX(reward_date) as latest_date
FROM daily_rewards;
