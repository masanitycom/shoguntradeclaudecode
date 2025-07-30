-- 異常なユーザーデータの調査

SELECT '=== INVESTIGATING ABNORMAL USER DATA ===' as section;

-- 1. A1UP, A2UP などの異常な名前のユーザーを確認
SELECT 'Users with UP suffix names:' as info;
SELECT 
    id,
    name,
    email,
    user_id,
    created_at,
    referrer_id,
    phone,
    usdt_address
FROM users
WHERE name LIKE '%UP'
ORDER BY created_at DESC;

-- 2. @shogun-trade.com, @shogun-trade.co ドメインのユーザー
SELECT 'Users with shogun-trade domain emails:' as info;
SELECT 
    id,
    name,
    email,
    user_id,
    created_at,
    referrer_id
FROM users
WHERE email LIKE '%@shogun-trade.com%' 
   OR email LIKE '%@shogun-trade.co%'
ORDER BY created_at DESC;

-- 3. 2025/6/26に登録されたユーザー
SELECT 'Users registered on 2025/6/26:' as info;
SELECT 
    id,
    name,
    email,
    user_id,
    created_at
FROM users
WHERE DATE(created_at) = '2025-06-26'
ORDER BY name;

-- 4. これらのユーザーのNFT保有状況
SELECT 'NFT holdings for these users:' as info;
SELECT 
    u.name,
    u.email,
    un.id as user_nft_id,
    n.name as nft_name,
    un.is_active
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id
LEFT JOIN nfts n ON un.nft_id = n.id
WHERE u.email LIKE '%@shogun-trade.com%' 
   OR u.email LIKE '%@shogun-trade.co%'
   OR u.name LIKE '%UP'
ORDER BY u.name;

-- 5. auth.usersとの関連を確認
SELECT 'Auth users vs public users mismatch:' as info;
SELECT 
    au.email as auth_email,
    pu.email as public_email,
    pu.name as public_name,
    au.created_at as auth_created,
    pu.created_at as public_created
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE au.email LIKE '%@shogun-trade.com%' 
   OR au.email LIKE '%@shogun-trade.co%'
ORDER BY au.email;

SELECT 'Analysis complete - Check for data integrity issues' as status;