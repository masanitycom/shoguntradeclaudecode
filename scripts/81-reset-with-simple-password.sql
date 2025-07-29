-- 非常にシンプルなパスワードで再設定

UPDATE auth.users 
SET 
    encrypted_password = crypt('123456', gen_salt('bf')),
    updated_at = NOW()
WHERE email = 'kiyoji1948@gmail.com';

SELECT 'Password set to: 123456' as message;
