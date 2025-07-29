-- 重複ユーザーの修正

-- 1. OHTAKIYOの重複を修正（最新のレコードを残す）
WITH duplicate_ohtakiyo AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY created_at DESC) as rn
    FROM users 
    WHERE email = 'ohtakiyo@gmail.com'
)
DELETE FROM users 
WHERE id IN (
    SELECT id FROM duplicate_ohtakiyo WHERE rn > 1
);

-- 2. 他の重複ユーザーも修正
WITH duplicate_users AS (
    SELECT 
        id, 
        email,
        ROW_NUMBER() OVER (PARTITION BY email ORDER BY created_at DESC) as rn
    FROM users
)
DELETE FROM users 
WHERE id IN (
    SELECT id FROM duplicate_users WHERE rn > 1
);

-- 3. 認証ユーザーが存在しないユーザーの確認
SELECT 
    u.email,
    u.user_id
FROM users u
LEFT JOIN auth.users au ON u.email = au.email
WHERE au.id IS NULL;
