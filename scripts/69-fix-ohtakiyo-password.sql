-- OHTAKIYOユーザーのパスワードをリセット

-- パスワードを 'password123' にリセット
UPDATE auth.users 
SET 
    encrypted_password = crypt('password123', gen_salt('bf')),
    updated_at = now()
WHERE email = 'kiyoji1948@gmail.com';

-- 確認
SELECT 
    email,
    updated_at,
    last_sign_in_at
FROM auth.users 
WHERE email = 'kiyoji1948@gmail.com';
