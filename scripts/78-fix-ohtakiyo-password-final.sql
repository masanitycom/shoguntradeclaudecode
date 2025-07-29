-- OHTAKIYOユーザーのパスワードを確実に修正

-- 1. 現在の状況確認
SELECT 
    'Current OHTAKIYO status' as info,
    u.email,
    u.user_id,
    au.id IS NOT NULL as has_auth_record,
    au.email_confirmed_at IS NOT NULL as email_confirmed,
    au.created_at as auth_created
FROM users u
LEFT JOIN auth.users au ON u.email = au.email
WHERE u.user_id = 'OHTAKIYO';

-- 2. 認証レコードが存在する場合、パスワードを更新
UPDATE auth.users 
SET 
    encrypted_password = crypt('12345678', gen_salt('bf')),
    email_confirmed_at = NOW(),
    updated_at = NOW()
WHERE email = 'kiyoji1948@gmail.com';

-- 3. 認証レコードが存在しない場合、新規作成
INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    role
)
SELECT 
    gen_random_uuid(),
    'kiyoji1948@gmail.com',
    crypt('12345678', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '{"provider": "email", "providers": ["email"]}',
    '{}',
    false,
    'authenticated'
WHERE NOT EXISTS (
    SELECT 1 FROM auth.users WHERE email = 'kiyoji1948@gmail.com'
);

-- 4. 更新後の確認
SELECT 
    'Updated OHTAKIYO status' as info,
    u.email,
    u.user_id,
    au.id IS NOT NULL as has_auth_record,
    au.email_confirmed_at IS NOT NULL as email_confirmed,
    au.encrypted_password IS NOT NULL as has_password
FROM users u
LEFT JOIN auth.users au ON u.email = au.email
WHERE u.user_id = 'OHTAKIYO';

-- 5. テスト用の簡単なパスワード確認
SELECT 
    'Password test' as info,
    email,
    encrypted_password = crypt('12345678', encrypted_password) as password_matches
FROM auth.users 
WHERE email = 'kiyoji1948@gmail.com';
