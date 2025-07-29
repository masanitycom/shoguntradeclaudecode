-- 日利計算システムのテスト

-- 1. 2025-02-10の日利計算を実行
SELECT 
    '=== 日利計算実行 ===' as section,
    *
FROM calculate_daily_rewards('2025-02-10'::date);

-- 2. 計算結果の確認
SELECT 
    '=== 計算結果確認 ===' as section,
    COUNT(*) as total_rewards,
    SUM(reward_amount) as total_amount,
    AVG(reward_amount) as avg_reward,
    MIN(reward_amount) as min_reward,
    MAX(reward_amount) as max_reward
FROM daily_rewards
WHERE reward_date = '2025-02-10';

-- 3. ユーザー別の報酬確認
SELECT 
    '=== ユーザー別報酬 ===' as section,
    u.name as user_name,
    COUNT(dr.id) as nft_count,
    SUM(dr.reward_amount) as total_reward,
    AVG(dr.reward_amount) as avg_reward
FROM daily_rewards dr
JOIN users u ON dr.user_id = u.id
WHERE dr.reward_date = '2025-02-10'
GROUP BY u.id, u.name
ORDER BY total_reward DESC
LIMIT 10;

-- 4. NFT別の報酬確認
SELECT 
    '=== NFT別報酬 ===' as section,
    n.name as nft_name,
    n.daily_rate_limit,
    COUNT(dr.id) as count,
    SUM(dr.reward_amount) as total_reward,
    AVG(dr.reward_amount) as avg_reward
FROM daily_rewards dr
JOIN nfts n ON dr.nft_id = n.id
WHERE dr.reward_date = '2025-02-10'
GROUP BY n.id, n.name, n.daily_rate_limit
ORDER BY total_reward DESC;
