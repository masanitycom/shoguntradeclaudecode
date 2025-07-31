-- NFTが消失したユーザーの調査（修正版）

SELECT '=== INVESTIGATING MISSING NFTs (FIXED) ===' as section;

-- 1. NFTを持っていないユーザーの確認
SELECT 'Users without active NFTs:' as info;
SELECT 
    u.id,
    u.name,
    u.email,
    u.created_at,
    CASE 
        WHEN u.name LIKE 'ユーザー%' THEN 'テストユーザー'
        WHEN u.name LIKE '%UP' THEN 'UP系ユーザー'  
        WHEN u.phone = '000-0000-0000' THEN 'テスト電話番号'
        ELSE '通常ユーザー'
    END as user_type
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE un.user_id IS NULL
ORDER BY u.created_at DESC
LIMIT 20;

-- 2. 非アクティブ化されたNFTがあるユーザー
SELECT 'Users with deactivated NFTs:' as info;
SELECT 
    u.id,
    u.name,
    u.email,
    un.id as user_nft_id,
    n.name as nft_name,
    un.purchase_date,
    un.operation_start_date,
    un.total_earned,
    un.is_active,
    un.updated_at as last_update
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = false
ORDER BY un.updated_at DESC
LIMIT 10;

-- 3. 報酬データがあるのにNFTがないユーザー
SELECT 'Users with reward history but no active NFT:' as info;
SELECT 
    u.id,
    u.name,
    u.email,
    COUNT(dr.id) as reward_count,
    SUM(dr.amount) as total_rewards_from_history
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
LEFT JOIN daily_rewards dr ON u.id = dr.user_id
WHERE un.user_id IS NULL
  AND dr.user_id IS NOT NULL
GROUP BY u.id, u.name, u.email
ORDER BY reward_count DESC
LIMIT 10;

-- 4. テストユーザーと実ユーザーの分類
SELECT 'Classification summary:' as info;
SELECT 
    CASE 
        WHEN u.name LIKE 'ユーザー%' THEN 'ユーザー系テストデータ'
        WHEN u.name LIKE '%UP' THEN 'UP系テストデータ'
        WHEN u.phone = '000-0000-0000' THEN 'テスト電話番号'
        WHEN u.email LIKE '%@shogun-trade.com%' AND u.email != 'admin@shogun-trade.com' THEN 'shogun-tradeドメイン'
        ELSE '通常ユーザー'
    END as classification,
    COUNT(*) as total_count,
    COUNT(CASE WHEN un.user_id IS NULL THEN 1 END) as without_nft,
    COUNT(CASE WHEN un.user_id IS NOT NULL THEN 1 END) as with_nft
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
GROUP BY 
    CASE 
        WHEN u.name LIKE 'ユーザー%' THEN 'ユーザー系テストデータ'
        WHEN u.name LIKE '%UP' THEN 'UP系テストデータ'
        WHEN u.phone = '000-0000-0000' THEN 'テスト電話番号'
        WHEN u.email LIKE '%@shogun-trade.com%' AND u.email != 'admin@shogun-trade.com' THEN 'shogun-tradeドメイン'
        ELSE '通常ユーザー'
    END
ORDER BY total_count DESC;

-- 5. 実ユーザーでNFTがないケース（要注意）
SELECT 'Real users without NFTs (CRITICAL):' as critical_info;
SELECT 
    u.id,
    u.name,
    u.email,
    u.created_at,
    u.phone,
    '要確認：実ユーザーなのにNFTなし' as status
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE un.user_id IS NULL
  AND u.name NOT LIKE 'ユーザー%'
  AND u.name NOT LIKE '%UP'
  AND COALESCE(u.phone, '') != '000-0000-0000'
  AND u.email NOT LIKE '%@shogun-trade.com%'
ORDER BY u.created_at DESC;

SELECT '=== MISSING NFT INVESTIGATION COMPLETE (FIXED) ===' as status;