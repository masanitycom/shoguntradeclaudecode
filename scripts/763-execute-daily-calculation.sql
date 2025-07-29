-- 修正後の日利計算を実行

-- 1. 2025-02-10（月曜日）の日利計算を実行
SELECT 
    '=== 2025-02-10 日利計算実行 ===' as section,
    *
FROM calculate_daily_rewards('2025-02-10'::date);

-- 2. 計算結果の詳細確認
SELECT 
    '=== 計算結果詳細 ===' as section,
    COUNT(*) as total_rewards,
    SUM(reward_amount) as total_amount,
    AVG(reward_amount) as avg_reward,
    MIN(reward_amount) as min_reward,
    MAX(reward_amount) as max_reward,
    COUNT(DISTINCT user_id) as unique_users
FROM daily_rewards
WHERE reward_date = '2025-02-10';

-- 3. グループ別の計算結果
SELECT 
    '=== グループ別結果 ===' as section,
    drg.group_name,
    COUNT(dr.id) as reward_count,
    SUM(dr.reward_amount) as total_rewards,
    AVG(dr.reward_amount) as avg_reward,
    (dr.daily_rate * 100)::numeric(5,2) as daily_rate_percent
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
WHERE dr.reward_date = '2025-02-10'
GROUP BY drg.group_name, dr.daily_rate
ORDER BY total_rewards DESC;

-- 4. 上位ユーザーの報酬確認
SELECT 
    '=== 上位ユーザー報酬 ===' as section,
    u.name as user_name,
    COUNT(dr.id) as nft_count,
    SUM(dr.reward_amount) as daily_reward,
    SUM(un.purchase_price) as total_investment,
    (SUM(dr.reward_amount) / SUM(un.purchase_price) * 100)::numeric(5,2) as daily_return_percent
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN users u ON dr.user_id = u.id
WHERE dr.reward_date = '2025-02-10'
GROUP BY u.id, u.name
ORDER BY daily_reward DESC
LIMIT 15;

-- 5. NFT別の報酬確認
SELECT 
    '=== NFT別報酬 ===' as section,
    n.name as nft_name,
    n.daily_rate_limit,
    COUNT(dr.id) as count,
    SUM(dr.reward_amount) as total_reward,
    AVG(dr.reward_amount) as avg_reward,
    (dr.daily_rate * 100)::numeric(5,2) as daily_rate_percent
FROM daily_rewards dr
JOIN nfts n ON dr.nft_id = n.id
WHERE dr.reward_date = '2025-02-10'
GROUP BY n.id, n.name, n.daily_rate_limit, dr.daily_rate
ORDER BY total_reward DESC;
