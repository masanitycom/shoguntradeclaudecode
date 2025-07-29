-- メールアドレスの不整合を確認

-- OHTAKIYOユーザーの現在の状況
SELECT 
    u.name,
    u.user_id,
    u.email as users_table_email,
    au.email as auth_table_email,
    au.id as auth_user_id
FROM users u
LEFT JOIN auth.users au ON u.id = au.id
WHERE u.user_id = 'OHTAKIYO';

-- 元のメールアドレスでauth.usersを検索
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at
FROM auth.users 
WHERE email = 'kiyoji1948@gmail.com';

-- 全体的な不整合チェック
SELECT 
    u.user_id,
    u.email as users_email,
    au.email as auth_email,
    CASE 
        WHEN u.email = au.email THEN '一致'
        ELSE '不一致'
    END as status
FROM users u
LEFT JOIN auth.users au ON u.id = au.id
WHERE u.email != au.email OR au.email IS NULL
LIMIT 10;
