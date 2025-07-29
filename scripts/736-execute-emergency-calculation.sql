-- 🚀 緊急日利計算実行

-- 1. 現在の状況確認
SELECT 
    '=== 計算前の状況 ===' as section,
    COUNT(un.id) as active_nfts,
    SUM(n.price) as total_investment,
    SUM(un.total_earned) as current_total_earned,
    COUNT(dr.id) as existing_rewards
FROM user_nfts un
JOIN nfts n ON un.nft_id = n.id
LEFT JOIN daily_rewards dr ON dr.user_nft_id = un.id
WHERE un.is_active = true;

-- 2. 今日の日利計算を強制実行
SELECT 
    '=== 日利計算実行 ===' as section,
    success,
    message,
    processed_count,
    total_amount
FROM force_daily_calculation();

-- 3. 計算後の状況確認
SELECT 
    '=== 計算後の状況 ===' as section,
    COUNT(un.id) as active_nfts,
    SUM(n.price) as total_investment,
    SUM(un.total_earned) as new_total_earned,
    COUNT(dr.id) as total_rewards,
    COALESCE(SUM(dr.reward_amount), 0) as total_reward_amount
FROM user_nfts un
JOIN nfts n ON un.nft_id = n.id
LEFT JOIN daily_rewards dr ON dr.user_nft_id = un.id
WHERE un.is_active = true;

-- 4. ユーザー別の結果確認
SELECT 
    '=== ユーザー別結果 ===' as section,
    u.name as user_name,
    COUNT(un.id) as nft_count,
    SUM(n.price) as investment,
    SUM(un.total_earned) as total_earned,
    COUNT(dr.id) as reward_count,
    COALESCE(SUM(dr.reward_amount), 0) as today_rewards
FROM users u
JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
JOIN nfts n ON un.nft_id = n.id
LEFT JOIN daily_rewards dr ON dr.user_nft_id = un.id AND dr.reward_date = CURRENT_DATE
WHERE u.is_admin = false
GROUP BY u.id, u.name
ORDER BY investment DESC;

-- 5. 今日の日利詳細
SELECT 
    '=== 今日の日利詳細 ===' as section,
    dr.user_nft_id,
    dr.reward_amount,
    n.name as nft_name,
    n.price as nft_price,
    u.name as user_name
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
JOIN users u ON un.user_id = u.id
WHERE dr.reward_date = CURRENT_DATE
ORDER BY dr.reward_amount DESC;

SELECT '🚀 緊急日利計算実行完了' as status;
