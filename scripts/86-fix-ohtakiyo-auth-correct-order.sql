-- OHTAKIYOユーザーの認証問題を正しい順序で修正

-- 1. まず不要な重複auth.usersレコードを削除
DELETE FROM auth.users 
WHERE id = '2c5589e3-2f47-43fc-8acf-72a2b254a59d'
AND email = 'kiyoji1948@gmail.com';

-- 2. その後、正しいauth.usersレコードのメールアドレスを修正
UPDATE auth.users 
SET email = 'kiyoji1948@gmail.com',
    raw_user_meta_data = '{"name": "オオタキヨジ", "user_id": "OHTAKIYO"}'::jsonb,
    updated_at = NOW()
WHERE id = 'd8c1b7a2-20ea-4991-a296-00a090a36e41';

-- 3. 修正結果を確認
SELECT 
  'Fixed auth record' as status,
  id,
  email,
  raw_user_meta_data,
  updated_at
FROM auth.users 
WHERE id = 'd8c1b7a2-20ea-4991-a296-00a090a36e41';

-- 4. 関連付け確認
SELECT 
  u.name,
  u.user_id,
  u.email as users_email,
  au.email as auth_email,
  'NOW LINKED' as status
FROM users u
JOIN auth.users au ON u.id = au.id
WHERE u.user_id = 'OHTAKIYO';
