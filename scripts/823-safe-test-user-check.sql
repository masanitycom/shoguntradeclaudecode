-- 安全なテストユーザーチェック

SELECT '=== SAFE TEST USER CHECK ===' as section;

-- 1. 明確なテストユーザーパターン
SELECT 'Clear test user patterns:' as info;
SELECT 
    COUNT(*) as count,
    'ユーザー系テストデータ' as pattern
FROM users
WHERE name LIKE 'ユーザー%'
UNION ALL
SELECT 
    COUNT(*) as count,
    'UP系テストデータ' as pattern
FROM users
WHERE name LIKE '%UP'
UNION ALL
SELECT 
    COUNT(*) as count,
    'テスト電話番号' as pattern  
FROM users
WHERE phone = '000-0000-0000'
UNION ALL
SELECT 
    COUNT(*) as count,
    'shogun-tradeドメイン（admin除く）' as pattern
FROM users
WHERE email LIKE '%@shogun-trade.com%' 
  AND email != 'admin@shogun-trade.com';

-- 2. 削除推奨テストユーザーリスト（サンプル10件）
SELECT 'Test users recommended for deletion (sample):' as info;
SELECT 
    u.id,
    u.name,
    u.email,
    u.phone,
    u.created_at,
    CASE 
        WHEN u.name LIKE 'ユーザー%' THEN 'ユーザー系'
        WHEN u.name LIKE '%UP' THEN 'UP系'
        WHEN u.phone = '000-0000-0000' THEN 'テスト電話'
        WHEN u.email LIKE '%@shogun-trade.com%' AND u.email != 'admin@shogun-trade.com' THEN 'テストドメイン'
    END as test_type
FROM users u
WHERE (
    u.name LIKE 'ユーザー%'
    OR u.name LIKE '%UP'
    OR u.phone = '000-0000-0000'
    OR (u.email LIKE '%@shogun-trade.com%' AND u.email != 'admin@shogun-trade.com')
)
ORDER BY u.created_at DESC
LIMIT 10;

-- 3. 実ユーザーの確認（NFTありなし両方）
SELECT 'Real users status:' as info;
SELECT 
    u.id,
    u.name,
    u.email,
    u.created_at,
    CASE WHEN un.user_id IS NOT NULL THEN 'NFTあり' ELSE 'NFTなし' END as nft_status
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE u.name NOT LIKE 'ユーザー%'
  AND u.name NOT LIKE '%UP'
  AND COALESCE(u.phone, '') != '000-0000-0000'
  AND u.email NOT LIKE '%@shogun-trade.com%'
ORDER BY u.created_at DESC
LIMIT 10;

-- 4. 削除対象サマリー
SELECT 'Deletion summary:' as summary;
SELECT 
    'Total test users to delete' as description,
    COUNT(*) as count
FROM users
WHERE (
    name LIKE 'ユーザー%'
    OR name LIKE '%UP'
    OR phone = '000-0000-0000'
    OR (email LIKE '%@shogun-trade.com%' AND email != 'admin@shogun-trade.com')
);

SELECT '=== SAFE CHECK COMPLETE ===' as status;