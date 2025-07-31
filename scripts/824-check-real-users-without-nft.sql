-- 実ユーザーでNFTがない人の詳細確認

SELECT '=== REAL USERS WITHOUT NFT ANALYSIS ===' as section;

-- 1. 実ユーザーでNFTがない人の詳細
SELECT 'Real users without NFT - detailed analysis:' as info;
SELECT 
    u.id,
    u.name,
    u.email,
    u.created_at,
    u.total_investment,
    u.total_earned,
    u.active_nft_count,
    CASE 
        WHEN u.total_investment > 0 THEN '投資額あり - NFT復旧検討必要'
        WHEN u.total_earned > 0 THEN '報酬履歴あり - NFT復旧検討必要'
        ELSE '新規ユーザー - NFT未購入'
    END as recovery_assessment
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE un.user_id IS NULL
  AND u.name NOT LIKE 'ユーザー%'
  AND u.name NOT LIKE '%UP'
  AND COALESCE(u.phone, '') != '000-0000-0000'
  AND u.email NOT LIKE '%@shogun-trade.com%';

-- 2. 非アクティブNFTを持つ実ユーザー
SELECT 'Real users with deactivated NFTs:' as info;
SELECT 
    u.id,
    u.name,
    u.email,
    n.name as nft_name,
    un.purchase_date,
    un.total_earned,
    un.is_active,
    un.updated_at,
    CASE 
        WHEN un.total_earned >= (n.price * 3) THEN '300%達成 - 正常完了'
        ELSE '非正常な非アクティブ化 - 要調査'
    END as deactivation_reason
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = false
  AND u.name NOT LIKE 'ユーザー%'
  AND u.name NOT LIKE '%UP'
  AND COALESCE(u.phone, '') != '000-0000-0000'
  AND u.email NOT LIKE '%@shogun-trade.com%';

-- 3. 報酬データがあるのにNFTがない実ユーザー
SELECT 'Real users with rewards but no NFT (DATA LOSS):' as critical;
SELECT 
    u.id,
    u.name,
    u.email,
    COUNT(dr.id) as reward_count,
    SUM(dr.amount) as total_reward_amount,
    MIN(dr.reward_date) as first_reward,
    MAX(dr.reward_date) as last_reward,
    '緊急：データ復旧が必要' as action_required
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
JOIN daily_rewards dr ON u.id = dr.user_id
WHERE un.user_id IS NULL
  AND u.name NOT LIKE 'ユーザー%'
  AND u.name NOT LIKE '%UP'
  AND COALESCE(u.phone, '') != '000-0000-0000'
  AND u.email NOT LIKE '%@shogun-trade.com%'
GROUP BY u.id, u.name, u.email;

SELECT '=== REAL USER NFT ANALYSIS COMPLETE ===' as status;