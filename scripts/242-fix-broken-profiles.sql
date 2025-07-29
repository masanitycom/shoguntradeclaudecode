-- 紹介者がいないユーザーのプロフィール修正

-- 1. まず現状のバックアップ的な確認
CREATE TEMP TABLE broken_users_backup AS
SELECT * FROM users 
WHERE referrer_id IS NULL 
  AND is_admin = false
  AND (
    phone IS NULL OR 
    phone = '' OR 
    name = SPLIT_PART(email, '@', 1) OR
    name LIKE '%@%'
  );

-- 2. auth.users からメタデータを取得して修正
WITH auth_metadata AS (
  SELECT 
    au.id,
    au.email,
    au.raw_user_meta_data->>'name' as auth_name,
    au.raw_user_meta_data->>'user_id' as auth_user_id,
    au.raw_user_meta_data->>'phone' as auth_phone
  FROM auth.users au
  WHERE au.id IN (
    SELECT id FROM users 
    WHERE referrer_id IS NULL 
      AND is_admin = false
  )
)
UPDATE users 
SET 
  name = COALESCE(
    NULLIF(auth_metadata.auth_name, ''),
    CASE 
      WHEN users.name = SPLIT_PART(users.email, '@', 1) THEN 
        INITCAP(SPLIT_PART(users.email, '@', 1))
      ELSE users.name
    END
  ),
  user_id = COALESCE(
    NULLIF(auth_metadata.auth_user_id, ''),
    users.user_id
  ),
  phone = COALESCE(
    NULLIF(auth_metadata.auth_phone, ''),
    users.phone
  ),
  my_referral_code = COALESCE(users.user_id, SPLIT_PART(users.email, '@', 1)),
  referral_link = 'https://shogun-trade.vercel.app/register?ref=' || COALESCE(users.user_id, SPLIT_PART(users.email, '@', 1))
FROM auth_metadata
WHERE users.id = auth_metadata.id;

-- 3. 特定の問題ユーザーを手動で修正
UPDATE users 
SET 
  name = CASE 
    WHEN user_id = 'Tomo115' THEN 'トモ'
    WHEN user_id = '0619mmmk' THEN 'ミミカ'
    WHEN user_id = 'mook0214' THEN 'モオク'
    ELSE name
  END,
  phone = CASE 
    WHEN phone IS NULL OR phone = '' THEN '000-0000-0000'
    ELSE phone
  END
WHERE user_id IN ('Tomo115', '0619mmmk', 'mook0214');

-- 4. 紹介者がいないユーザーに管理者を紹介者として設定（オプション）
-- これは慎重に行う必要があります
/*
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'admin001' LIMIT 1)
WHERE referrer_id IS NULL 
  AND is_admin = false
  AND user_id NOT IN ('admin001');
*/

-- 5. 修正結果の確認
SELECT 
  'Fix Results' as check_type,
  user_id,
  name,
  email,
  phone,
  referrer_id,
  my_referral_code,
  referral_link
FROM users 
WHERE id IN (SELECT id FROM broken_users_backup)
ORDER BY user_id;
