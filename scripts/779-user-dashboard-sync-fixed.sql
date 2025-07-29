-- 🔄 ユーザーダッシュボードデータ同期

-- 1. ユーザーの総投資額と総報酬を更新
UPDATE users 
SET 
    total_investment = COALESCE(user_totals.total_investment, 0),
    total_rewards = COALESCE(user_totals.total_rewards, 0),
    updated_at = NOW()
FROM (
    SELECT 
        u.id as user_id,
        COALESCE(SUM(un.purchase_price), 0) as total_investment,
        COALESCE(SUM(dr.reward_amount), 0) as total_rewards
    FROM users u
    LEFT JOIN user_nfts un ON u.id = un.user_id
    LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id
    WHERE u.is_admin = false
    GROUP BY u.id
) user_totals
WHERE users.id = user_totals.user_id;

-- 2. 各ユーザーNFTの累計報酬を更新
UPDATE user_nfts 
SET 
    total_rewards = COALESCE(nft_totals.total_rewards, 0),
    updated_at = NOW()
FROM (
    SELECT 
        un.id as user_nft_id,
        COALESCE(SUM(dr.reward_amount), 0) as total_rewards
    FROM user_nfts un
    LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id
    GROUP BY un.id
) nft_totals
WHERE user_nfts.id = nft_totals.user_nft_id;

-- 3. 同期結果の確認
SELECT '=== ダッシュボード同期結果 ===' as section;

SELECT 
    u.email,
    u.name,
    u.total_investment,
    u.total_rewards,
    CASE 
        WHEN u.total_investment > 0 THEN 
            ROUND((u.total_rewards / u.total_investment * 100)::numeric, 2)
        ELSE 0
    END as total_return_percent,
    COUNT(un.id) as nft_count
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id
WHERE u.is_admin = false
GROUP BY u.id, u.email, u.name, u.total_investment, u.total_rewards
ORDER BY u.email;

-- 4. NFT別の詳細情報
SELECT '=== NFT別詳細情報 ===' as section;

SELECT 
    u.email,
    n.name as nft_name,
    un.purchase_price,
    un.total_rewards,
    CASE 
        WHEN un.purchase_price > 0 THEN 
            ROUND((un.total_rewards / un.purchase_price * 100)::numeric, 2)
        ELSE 0
    END as nft_return_percent,
    drg.group_name,
    un.operation_start_date
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
LEFT JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
WHERE u.is_admin = false
ORDER BY u.email, n.name;

-- 5. 最新の報酬状況
SELECT '=== 最新報酬状況 ===' as section;

SELECT 
    dr.reward_date,
    COUNT(*) as reward_count,
    SUM(dr.reward_amount) as total_amount,
    ROUND(AVG(dr.reward_amount)::numeric, 2) as avg_amount
FROM daily_rewards dr
WHERE dr.reward_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY dr.reward_date
ORDER BY dr.reward_date DESC;

-- 完了メッセージ
SELECT 'User dashboard data synchronized successfully' as status;
