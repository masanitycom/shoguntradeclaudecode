-- パスワード更新の確認

-- 1. パスワードハッシュの確認
SELECT 
    'Password verification' as info,
    email,
    encrypted_password IS NOT NULL as has_password,
    encrypted_password = crypt('12345678', encrypted_password) as password_12345678_matches,
    encrypted_password = crypt('password', encrypted_password) as password_simple_matches,
    length(encrypted_password) as password_hash_length
FROM auth.users 
WHERE email = 'kiyoji1948@gmail.com';

-- 2. 強制的にパスワードを再設定（bcryptハッシュを使用）
UPDATE auth.users 
SET 
    encrypted_password = '$2a$10$' || encode(digest('12345678' || email, 'sha256'), 'hex'),
    updated_at = NOW()
WHERE email = 'kiyoji1948@gmail.com';

-- 3. Supabase標準のパスワードハッシュ形式で再設定
UPDATE auth.users 
SET 
    encrypted_password = crypt('12345678', gen_salt('bf', 10)),
    updated_at = NOW()
WHERE email = 'kiyoji1948@gmail.com';

-- 4. 最終確認
SELECT 
    'Final password check' as info,
    email,
    encrypted_password IS NOT NULL as has_password,
    substring(encrypted_password, 1, 10) as password_prefix,
    updated_at
FROM auth.users 
WHERE email = 'kiyoji1948@gmail.com';
