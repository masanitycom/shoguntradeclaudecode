-- 認証問題の包括的分析（本番環境安全版）

-- 1. 問題のユーザーIDの詳細調査
SELECT '=== 問題のユーザー1の詳細調査 ===' as section;
SELECT 
    'users テーブル検索' as search_type,
    id, 
    name, 
    email, 
    user_id as display_user_id,
    created_at,
    updated_at
FROM users 
WHERE id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
   OR email = 'kappystone.516@gmail.com'
   OR email = 'phu55papa@gmail.com';

-- 2. user_nftsテーブルでの関連データ
SELECT '=== NFT保有状況の調査 ===' as section;
SELECT 
    un.user_id,
    u.name as owner_name,
    u.email as owner_email,
    un.id as nft_record_id,
    n.name as nft_name,
    un.current_investment,
    un.is_active,
    un.created_at
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
   OR u.email IN ('kappystone.516@gmail.com', 'phu55papa@gmail.com');

-- 3. 重複や孤立したレコードの検出
SELECT '=== 重複・孤立レコード検出 ===' as section;
SELECT 
    'email重複チェック' as check_type,
    email,
    COUNT(*) as duplicate_count,
    array_agg(id) as user_ids,
    array_agg(name) as names
FROM users 
WHERE email IN ('kappystone.516@gmail.com', 'phu55papa@gmail.com', 'tokusana371@gmail.com')
GROUP BY email;

-- 4. 最近の認証関連の活動
SELECT '=== 最近のユーザープロファイル ===' as section;
SELECT 
    id,
    name,
    email,
    user_id as display_user_id,
    created_at,
    CASE 
        WHEN email = 'kappystone.516@gmail.com' THEN '期待されるログインユーザー'
        WHEN email = 'phu55papa@gmail.com' THEN '表示されているユーザー'
        WHEN email = 'tokusana371@gmail.com' THEN '2番目の問題ユーザー'
        ELSE 'その他'
    END as user_type
FROM users 
WHERE email IN ('kappystone.516@gmail.com', 'phu55papa@gmail.com', 'tokusana371@gmail.com')
   OR id IN ('3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c', '359f44c4-507e-4867-b25d-592f98962145')
ORDER BY created_at DESC;

-- 5. UUIDの整合性チェック
SELECT '=== UUID整合性チェック ===' as section;
SELECT 
    'UUID形式検証' as check_type,
    id,
    name,
    email,
    CASE 
        WHEN id::text ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' 
        THEN 'Valid UUID'
        ELSE 'Invalid UUID'
    END as uuid_validity
FROM users 
WHERE id IN ('3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c', '359f44c4-507e-4867-b25d-592f98962145')
   OR email IN ('kappystone.516@gmail.com', 'phu55papa@gmail.com', 'tokusana371@gmail.com');