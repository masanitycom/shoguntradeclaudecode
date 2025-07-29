-- 最終的な過去分計算の実行

-- 1. 過去分計算を実行（週2-19）
SELECT 'Starting historical calculation for weeks 2-19...' as status;

SELECT * FROM calculate_nft_historical_rewards_final(2, 19);

-- 2. 計算結果の詳細確認
SELECT 'Calculation completed. Verifying results...' as status;

-- NFT別の計算サマリー
SELECT 
    n.name as nft_name,
    COUNT(dr.id) as total_rewards,
    SUM(dr.reward_amount) as total_amount,
    AVG(dr.reward_amount) as avg_daily_reward,
    MIN(dr.reward_date) as first_reward_date,
    MAX(dr.reward_date) as last_reward_date
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
WHERE dr.reward_date >= '2025-01-13'  -- 第2週の月曜日
AND dr.reward_date <= '2025-06-27'    -- 第19週の金曜日
GROUP BY n.id, n.name
ORDER BY n.name;

-- 週別の計算サマリー
SELECT 
    EXTRACT(WEEK FROM dr.reward_date) - 1 as week_number,
    COUNT(dr.id) as total_rewards,
    SUM(dr.reward_amount) as total_amount,
    COUNT(DISTINCT un.nft_id) as unique_nfts,
    COUNT(DISTINCT dr.user_nft_id) as unique_user_nfts
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
WHERE dr.reward_date >= '2025-01-13'
AND dr.reward_date <= '2025-06-27'
GROUP BY EXTRACT(WEEK FROM dr.reward_date)
ORDER BY week_number;

-- SHOGUN NFT 100000の特別確認（週2-9は0%のはず）
SELECT 
    dr.reward_date,
    dr.daily_rate,
    dr.reward_amount,
    EXTRACT(WEEK FROM dr.reward_date) - 1 as week_number
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
WHERE n.name = 'SHOGUN NFT 100000'
AND dr.reward_date >= '2025-01-13'  -- 第2週
AND dr.reward_date <= '2025-03-07'  -- 第9週
ORDER BY dr.reward_date;

-- 全体の計算統計
SELECT 
    'Historical calculation completed' as status,
    COUNT(dr.id) as total_historical_rewards,
    SUM(dr.reward_amount) as total_historical_amount,
    COUNT(DISTINCT dr.user_nft_id) as affected_user_nfts,
    MIN(dr.reward_date) as calculation_start_date,
    MAX(dr.reward_date) as calculation_end_date
FROM daily_rewards dr
WHERE dr.reward_date >= '2025-01-13'
AND dr.reward_date <= '2025-06-27';

-- ユーザー別の過去分報酬上位10名
SELECT 
    u.username,
    COUNT(dr.id) as total_reward_days,
    SUM(dr.reward_amount) as total_historical_rewards,
    AVG(dr.reward_amount) as avg_daily_reward
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN users u ON un.user_id = u.id
WHERE dr.reward_date >= '2025-01-13'
AND dr.reward_date <= '2025-06-27'
GROUP BY u.id, u.username
ORDER BY total_historical_rewards DESC
LIMIT 10;

-- 日利率の分布確認
SELECT 
    dr.daily_rate,
    COUNT(*) as frequency,
    SUM(dr.reward_amount) as total_amount
FROM daily_rewards dr
WHERE dr.reward_date >= '2025-01-13'
AND dr.reward_date <= '2025-06-27'
GROUP BY dr.daily_rate
ORDER BY dr.daily_rate;
