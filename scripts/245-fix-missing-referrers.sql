-- 紹介者の修正（実際のデータに基づいて）

-- 1. 同じ紹介コードを使っているユーザーから紹介者を特定して修正
WITH referrer_mapping AS (
  SELECT DISTINCT
    no_ref.id as user_id,
    no_ref.user_id as user_code,
    no_ref.referral_code,
    u3.id as correct_referrer_id,
    u3.user_id as correct_referrer_code
  FROM users no_ref
  LEFT JOIN users u2 ON no_ref.referral_code = u2.referral_code 
    AND u2.referrer_id IS NOT NULL
  LEFT JOIN users u3 ON u2.referrer_id = u3.id
  WHERE no_ref.referrer_id IS NULL 
    AND no_ref.is_admin = false
    AND no_ref.referral_code IS NOT NULL
    AND u3.id IS NOT NULL
)
UPDATE users 
SET 
  referrer_id = referrer_mapping.correct_referrer_id,
  updated_at = NOW()
FROM referrer_mapping
WHERE users.id = referrer_mapping.user_id;

-- 2. auth.usersのメタデータから紹介者情報を復元
WITH auth_referrer_data AS (
  SELECT 
    au.id,
    au.raw_user_meta_data->>'referrer_id' as meta_referrer_id,
    au.raw_user_meta_data->>'referral_code' as meta_referral_code,
    -- 紹介者IDまたは紹介コードから実際の紹介者を特定
    COALESCE(
      (SELECT id FROM users WHERE user_id = au.raw_user_meta_data->>'referrer_id'),
      (SELECT id FROM users WHERE my_referral_code = au.raw_user_meta_data->>'referral_code')
    ) as actual_referrer_id
  FROM auth.users au
  WHERE au.id IN (
    SELECT id FROM users 
    WHERE referrer_id IS NULL 
      AND is_admin = false
  )
  AND (
    au.raw_user_meta_data->>'referrer_id' IS NOT NULL OR
    au.raw_user_meta_data->>'referral_code' IS NOT NULL
  )
)
UPDATE users 
SET 
  referrer_id = auth_referrer_data.actual_referrer_id,
  referral_code = COALESCE(users.referral_code, auth_referrer_data.meta_referral_code),
  updated_at = NOW()
FROM auth_referrer_data
WHERE users.id = auth_referrer_data.id
  AND auth_referrer_data.actual_referrer_id IS NOT NULL;

-- 3. 修正結果の確認
SELECT 
  'Fix Results Summary' as check_type,
  COUNT(*) as total_users,
  COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) as users_with_referrer,
  COUNT(CASE WHEN referrer_id IS NULL THEN 1 END) as users_without_referrer,
  ROUND(COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) as referrer_percentage
FROM users 
WHERE is_admin = false;

-- 4. まだ紹介者がいないユーザーの詳細
SELECT 
  'Still Missing Referrers' as check_type,
  user_id,
  name,
  email,
  referral_code,
  created_at
FROM users 
WHERE referrer_id IS NULL 
  AND is_admin = false
ORDER BY created_at
LIMIT 20;
