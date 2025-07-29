-- 緊急計算実行とテスト

-- 1. 既存の今日の報酬をクリア（重複を避けるため）
DELETE FROM daily_rewards WHERE reward_date = CURRENT_DATE;

-- 2. 日利計算を実行
SELECT * FROM force_daily_calculation();

-- 3. 計算結果を確認
SELECT 
    COUNT(*) as total_rewards,
    SUM(reward_amount) as total_amount,
    AVG(reward_amount) as avg_reward,
    MIN(reward_amount) as min_reward,
    MAX(reward_amount) as max_reward
FROM daily_rewards 
WHERE reward_date = CURRENT_DATE;

-- 4. ユーザー別の報酬確認
SELECT 
    u.name,
    COUNT(dr.id) as nft_count,
    SUM(dr.reward_amount) as total_reward,
    AVG(dr.reward_amount) as avg_reward
FROM daily_rewards dr
JOIN users u ON dr.user_id = u.id
WHERE dr.reward_date = CURRENT_DATE
GROUP BY u.id, u.name
ORDER BY total_reward DESC
LIMIT 10;

-- 5. NFT別の報酬確認
SELECT 
    n.name as nft_name,
    n.price,
    COUNT(dr.id) as user_count,
    AVG(dr.reward_amount) as avg_reward,
    SUM(dr.reward_amount) as total_reward
FROM daily_rewards dr
JOIN nfts n ON dr.nft_id = n.id
WHERE dr.reward_date = CURRENT_DATE
GROUP BY n.id, n.name, n.price
ORDER BY n.price;
