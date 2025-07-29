-- OHTAKIYOユーザーの認証問題を修正

-- 1. 正しいauth.usersレコードのメールアドレスを修正
UPDATE auth.users 
SET email = 'kiyoji1948@gmail.com',
    raw_user_meta_data = '{"name": "オオタキヨジ", "user_id": "OHTAKIYO"}'::jsonb,
    updated_at = NOW()
WHERE id = 'd8c1b7a2-20ea-4991-a296-00a090a36e41';

-- 2. 不要な重複auth.usersレコードを削除
DELETE FROM auth.users 
WHERE id = '2c5589e3-2f47-43fc-8acf-72a2b254a59d';

-- 3. 修正結果を確認
SELECT 
  'Fixed auth record' as status,
  id,
  email,
  raw_user_meta_data,
  updated_at
FROM auth.users 
WHERE id = 'd8c1b7a2-20ea-4991-a296-00a090a36e41';
