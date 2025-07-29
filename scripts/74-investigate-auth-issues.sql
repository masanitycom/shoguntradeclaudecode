-- 認証問題の詳細調査
SELECT 
    'users table count' as check_type,
    COUNT(*) as count
FROM users;

SELECT 
    'auth.users table count' as check_type,
    COUNT(*) as count
FROM auth.users;

-- 重複ユーザーの確認
SELECT 
    email,
    COUNT(*) as count
FROM users 
GROUP BY email 
HAVING COUNT(*) > 1;

-- OHTAKIYOユーザーの詳細確認
SELECT 
    u.id as user_id,
    u.email as user_email,
    u.user_id as user_user_id,
    au.id as auth_id,
    au.email as auth_email,
    au.encrypted_password IS NOT NULL as has_password
FROM users u
LEFT JOIN auth.users au ON u.email = au.email
WHERE u.email = 'ohtakiyo@gmail.com'
ORDER BY u.created_at;

-- 全ユーザーの認証状況確認
SELECT 
    u.email,
    u.user_id,
    COUNT(u.id) as user_records,
    COUNT(au.id) as auth_records
FROM users u
LEFT JOIN auth.users au ON u.email = au.email
GROUP BY u.email, u.user_id
ORDER BY u.email;
