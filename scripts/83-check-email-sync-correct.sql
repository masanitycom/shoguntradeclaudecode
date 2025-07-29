-- OHTAKIYOユーザーのメールアドレス同期状況を確認
SELECT 
  'users table' as table_name,
  email,
  name,
  user_id,
  created_at
FROM users 
WHERE name = 'OHTAKIYO' OR user_id = 'OHTAKIYO';

-- auth.usersテーブルの情報（既に確認済み）
SELECT 
  'auth.users table' as table_name,
  email,
  id,
  email_confirmed_at,
  last_sign_in_at,
  raw_user_meta_data
FROM auth.users 
WHERE email = 'kiyoji1948@gmail.com';

-- 全てのユーザーでOHTAKIYOを含む名前を検索
SELECT 
  'Search OHTAKIYO in users' as info,
  name,
  user_id,
  email,
  created_at
FROM users 
WHERE name ILIKE '%OHTAKI%' OR user_id ILIKE '%OHTAKI%' OR email ILIKE '%ohtaki%';
