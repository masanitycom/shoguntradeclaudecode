-- 過去分計算結果の詳細確認

-- 1. NFT別の計算結果サマリー
SELECT 
    n.name as nft_name,
    COUNT(DISTINCT dr.reward_date) as calculation_days,
    COUNT(dr.id) as total_rewards,
    SUM(dr.reward_amount) as total_amount,
    AVG(dr.reward_amount) as avg_daily_reward,
    MIN(dr.reward_date) as first_reward_date,
    MAX(dr.reward_date) as last_reward_date
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
WHERE dr.calculation_type = 'HISTORICAL_CALCULATION'
GROUP BY n.id, n.name
ORDER BY n.name;

-- 2. 週別の報酬分布確認
SELECT 
    EXTRACT(WEEK FROM dr.reward_date) as week_number,
    COUNT(dr.id) as rewards_count,
    SUM(dr.reward_amount) as week_total,
    COUNT(DISTINCT dr.user_nft_id) as unique_nfts
FROM daily_rewards dr
WHERE dr.calculation_type = 'HISTORICAL_CALCULATION'
GROUP BY EXTRACT(WEEK FROM dr.reward_date)
ORDER BY week_number;

-- 3. SHOGUN NFT 100000の特別確認（週2-9は0%のはず）
SELECT 
    dr.reward_date,
    dr.daily_rate,
    dr.reward_amount,
    EXTRACT(WEEK FROM dr.reward_date) as week_number
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
WHERE n.name = 'SHOGUN NFT 100000'
AND dr.calculation_type = 'HISTORICAL_CALCULATION'
AND dr.reward_date BETWEEN '2025-01-13' AND '2025-03-07'  -- 週2-9の期間
ORDER BY dr.reward_date;

-- 4. ユーザー別の過去分報酬総額（上位10名）
SELECT 
    u.username,
    COUNT(dr.id) as total_rewards,
    SUM(dr.reward_amount) as total_amount,
    COUNT(DISTINCT un.nft_id) as nft_types
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN users u ON dr.user_id = u.id
WHERE dr.calculation_type = 'HISTORICAL_CALCULATION'
GROUP BY u.id, u.username
ORDER BY total_amount DESC
LIMIT 10;

-- 5. 日利率別の分布確認
SELECT 
    dr.daily_rate,
    COUNT(dr.id) as frequency,
    SUM(dr.reward_amount) as total_amount
FROM daily_rewards dr
WHERE dr.calculation_type = 'HISTORICAL_CALCULATION'
GROUP BY dr.daily_rate
ORDER BY dr.daily_rate;

-- 6. 計算完了ステータス
SELECT 
    'Historical calculation verification completed' as status,
    COUNT(*) as total_historical_rewards,
    COUNT(DISTINCT user_nft_id) as unique_user_nfts,
    COUNT(DISTINCT user_id) as unique_users,
    SUM(reward_amount) as total_rewards_amount,
    MIN(reward_date) as earliest_date,
    MAX(reward_date) as latest_date
FROM daily_rewards 
WHERE calculation_type = 'HISTORICAL_CALCULATION';
