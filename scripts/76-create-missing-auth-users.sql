-- 認証レコードが欠けているユーザーのためにauth.usersレコードを作成

-- まず、認証レコードが欠けているユーザーを確認
SELECT 
    u.email,
    u.user_id,
    'Missing auth record' as status
FROM users u
LEFT JOIN auth.users au ON u.email = au.email
WHERE au.id IS NULL
ORDER BY u.email;

-- 認証レコードが欠けているユーザーのためにauth.usersレコードを作成
-- パスワードは一時的に'12345678'に設定
INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
)
SELECT 
    gen_random_uuid(),
    u.email,
    crypt('12345678', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
FROM users u
LEFT JOIN auth.users au ON u.email = au.email
WHERE au.id IS NULL;

-- 作成結果を確認
SELECT 
    'Created auth records' as action,
    COUNT(*) as count
FROM users u
INNER JOIN auth.users au ON u.email = au.email;

-- OHTAKIYOユーザーの確認
SELECT 
    u.email,
    u.user_id,
    au.id IS NOT NULL as has_auth_record
FROM users u
LEFT JOIN auth.users au ON u.email = au.email
WHERE u.user_id = 'OHTAKIYO';
