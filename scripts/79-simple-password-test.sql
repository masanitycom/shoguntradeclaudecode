-- より簡単なパスワードでテスト

-- パスワードを'password'に設定
UPDATE auth.users 
SET 
    encrypted_password = crypt('password', gen_salt('bf')),
    email_confirmed_at = NOW(),
    updated_at = NOW()
WHERE email = 'kiyoji1948@gmail.com';

-- 確認
SELECT 
    'Simple password test' as info,
    email,
    encrypted_password = crypt('password', encrypted_password) as password_matches
FROM auth.users 
WHERE email = 'kiyoji1948@gmail.com';
