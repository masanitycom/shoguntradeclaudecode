-- 修正後の日利計算を実行

-- 1. 既存の計算結果をクリア
DELETE FROM daily_rewards WHERE reward_date = '2025-02-10';

-- 2. 修正後の日利計算を実行
SELECT 
    '=== 修正後日利計算実行 ===' as section,
    *
FROM calculate_daily_rewards('2025-02-10'::date);

-- 3. 計算結果の詳細確認
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

-- 4. グループ別の計算結果
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

-- 5. 上位報酬の確認
SELECT 
    '=== 上位報酬確認 ===' as section,
    u.name as user_name,
    n.name as nft_name,
    un.purchase_price,
    dr.reward_amount,
    (dr.reward_amount / un.purchase_price * 100)::numeric(5,2) as daily_return_percent
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
JOIN users u ON dr.user_id = u.id
WHERE dr.reward_date = '2025-02-10'
ORDER BY dr.reward_amount DESC
LIMIT 20;

-- 6. システム統計の更新
UPDATE users 
SET 
    total_earned = COALESCE((
        SELECT SUM(reward_amount) 
        FROM daily_rewards 
        WHERE user_id = users.id
    ), 0),
    updated_at = NOW()
WHERE id IN (
    SELECT DISTINCT user_id 
    FROM daily_rewards 
    WHERE reward_date = '2025-02-10'
);

SELECT '✅ 修正後日利計算完了' as status;
