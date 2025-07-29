-- OHTAKIYOユーザーのメールアドレス同期状況を確認
SELECT 
  'users table' as table_name,
  email,
  user_name,
  created_at
FROM users 
WHERE user_name = 'OHTAKIYO'

UNION ALL

SELECT 
  'auth.users table' as table_name,
  email,
  raw_user_meta_data->>'user_name' as user_name,
  created_at
FROM auth.users 
WHERE raw_user_meta_data->>'user_name' = 'OHTAKIYO'
   OR email LIKE '%ohtaki%'
   OR email = 'kiyoji1948@gmail.com';

-- 詳細な認証情報も確認
SELECT 
  'Detailed auth info' as info,
  id,
  email,
  email_confirmed_at,
  last_sign_in_at,
  raw_user_meta_data,
  updated_at
FROM auth.users 
WHERE raw_user_meta_data->>'user_name' = 'OHTAKIYO'
   OR email LIKE '%ohtaki%'
   OR email = 'kiyoji1948@gmail.com';
