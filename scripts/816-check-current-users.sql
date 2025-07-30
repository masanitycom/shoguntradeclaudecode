-- 現在のユーザー状況を確認

SELECT '=== CURRENT USERS STATUS ===' as section;

-- 1. 全ユーザー数
SELECT 'Total users:' as info;
SELECT COUNT(*) as total_users FROM users;

-- 2. ドメイン別ユーザー分布
SELECT 'Users by email domain:' as info;
SELECT 
    CASE 
        WHEN email LIKE '%@shogun-trade.com%' THEN '@shogun-trade.com'
        WHEN email LIKE '%@shogun-trade.co%' THEN '@shogun-trade.co'
        WHEN email LIKE '%@gmail.com%' THEN '@gmail.com'
        WHEN email LIKE '%@yahoo.com%' THEN '@yahoo.com'
        ELSE 'その他'
    END as domain,
    COUNT(*) as count
FROM users
GROUP BY 
    CASE 
        WHEN email LIKE '%@shogun-trade.com%' THEN '@shogun-trade.com'
        WHEN email LIKE '%@shogun-trade.co%' THEN '@shogun-trade.co'
        WHEN email LIKE '%@gmail.com%' THEN '@gmail.com'
        WHEN email LIKE '%@yahoo.com%' THEN '@yahoo.com'
        ELSE 'その他'
    END
ORDER BY count DESC;

-- 3. 異常なユーザー名パターン
SELECT 'Users with abnormal name patterns:' as info;
SELECT 
    name,
    email,
    phone,
    created_at,
    CASE 
        WHEN name LIKE 'ユーザー%' THEN 'ユーザー系'
        WHEN name LIKE '%UP' THEN 'UP系'
        WHEN name LIKE 'A%UP' THEN 'A*UP系'
        WHEN name LIKE 'テストユーザー%' THEN 'テストユーザー系'
        ELSE 'その他異常'
    END as pattern_type
FROM users
WHERE 
    name LIKE 'ユーザー%' 
    OR name LIKE '%UP'
    OR name LIKE 'テストユーザー%'
    OR phone = '000-0000-0000'
ORDER BY pattern_type, name;

-- 4. NFT保有状況
SELECT 'NFT ownership status:' as info;
SELECT 
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(DISTINCT user_id) FROM user_nfts WHERE is_active = true) as users_with_nft,
    (SELECT COUNT(*) FROM users) - (SELECT COUNT(DISTINCT user_id) FROM user_nfts WHERE is_active = true) as users_without_nft;

-- 5. 電話番号が000-0000-0000のユーザー
SELECT 'Users with test phone number:' as info;
SELECT COUNT(*) as test_phone_users
FROM users
WHERE phone = '000-0000-0000';

SELECT '=== USER ANALYSIS COMPLETE ===' as status;