-- 緊急: 認証とusersテーブルの同期チェック

-- 1. 問題のユーザーIDが存在するかチェック
SELECT 'Auth User 1 Check' as check_type;
SELECT 
    id, 
    name, 
    email, 
    user_id,
    created_at
FROM users 
WHERE id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

SELECT 'Auth User 2 Check' as check_type;
SELECT 
    id, 
    name, 
    email, 
    user_id,
    created_at
FROM users 
WHERE id = '359f44c4-507e-4867-b25d-592f98962145';

-- 2. メールアドレスでの検索
SELECT 'Email Search' as check_type;
SELECT 
    id, 
    name, 
    email, 
    user_id
FROM users 
WHERE email IN ('kappystone.516@gmail.com', 'tokusana371@gmail.com', 'phu55papa@gmail.com');

-- 3. 重複するユーザーIDがないかチェック
SELECT 'Duplicate ID Check' as check_type;
SELECT 
    id,
    COUNT(*) as count,
    array_agg(name) as names,
    array_agg(email) as emails
FROM users 
GROUP BY id
HAVING COUNT(*) > 1;

-- 4. 最近作成されたユーザーを確認
SELECT 'Recent Users' as check_type;
SELECT 
    id,
    name,
    email,
    user_id,
    created_at
FROM users 
ORDER BY created_at DESC
LIMIT 10;