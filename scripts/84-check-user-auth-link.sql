-- OHTAKIYOユーザーのusers.idとauth.users.idの関連付けを確認
SELECT 
  'users table' as source,
  id as user_id,
  name,
  user_id as login_id,
  email
FROM users 
WHERE user_id = 'OHTAKIYO';

SELECT 
  'auth.users table' as source,
  id as auth_id,
  email,
  email_confirmed_at,
  last_sign_in_at
FROM auth.users 
WHERE email = 'kiyoji1948@gmail.com';

-- 関連付けチェック
SELECT 
  u.id as users_id,
  u.name,
  u.user_id,
  u.email as users_email,
  au.id as auth_id,
  au.email as auth_email,
  CASE 
    WHEN u.id = au.id THEN 'LINKED'
    ELSE 'NOT LINKED'
  END as link_status
FROM users u
FULL OUTER JOIN auth.users au ON u.id = au.id
WHERE u.user_id = 'OHTAKIYO' OR au.email = 'kiyoji1948@gmail.com';
