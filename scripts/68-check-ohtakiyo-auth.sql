-- OHTAKIYOユーザーの認証状況を確認

-- 1. usersテーブルでの情報確認
SELECT 
    name,
    user_id,
    email,
    created_at,
    is_admin
FROM users 
WHERE user_id = 'OHTAKIYO' OR email = 'kiyoji1948@gmail.com';

-- 2. auth.usersテーブルでの認証情報確認
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at,
    updated_at,
    last_sign_in_at,
    raw_user_meta_data
FROM auth.users 
WHERE email = 'kiyoji1948@gmail.com';

-- 3. 両テーブルの関連性確認
SELECT 
    u.name,
    u.user_id,
    u.email as users_email,
    au.email as auth_email,
    au.email_confirmed_at,
    au.last_sign_in_at
FROM users u
LEFT JOIN auth.users au ON u.email = au.email
WHERE u.user_id = 'OHTAKIYO' OR u.email = 'kiyoji1948@gmail.com';
