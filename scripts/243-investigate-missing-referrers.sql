-- 紹介者がいないユーザーの詳細調査

-- 1. auth.usersのメタデータから紹介者情報を確認
SELECT 
  'Auth Metadata Check' as check_type,
  au.id,
  au.email,
  au.raw_user_meta_data,
  au.raw_user_meta_data->>'referrer_id' as auth_referrer_id,
  au.raw_user_meta_data->>'referral_code' as auth_referral_code,
  au.raw_user_meta_data->>'ref' as auth_ref,
  pu.user_id,
  pu.name,
  pu.referrer_id as current_referrer_id,
  pu.my_referral_code as current_my_referral_code
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.referrer_id IS NULL 
  AND pu.is_admin = false
  AND au.raw_user_meta_data IS NOT NULL
ORDER BY au.created_at
LIMIT 50;

-- 2. 登録時期による紹介関係の推測
SELECT 
  'Registration Timeline' as check_type,
  user_id,
  name,
  email,
  created_at,
  LAG(user_id) OVER (ORDER BY created_at) as prev_user,
  LAG(created_at) OVER (ORDER BY created_at) as prev_time,
  EXTRACT(EPOCH FROM (created_at - LAG(created_at) OVER (ORDER BY created_at)))/60 as minutes_diff
FROM users 
WHERE referrer_id IS NULL 
  AND is_admin = false
ORDER BY created_at
LIMIT 30;

-- 3. 紹介者候補の確認（早期登録ユーザー）
SELECT 
  'Potential Referrers' as check_type,
  user_id,
  name,
  email,
  my_referral_code,
  referral_link,
  created_at,
  (SELECT COUNT(*) FROM users u2 WHERE u2.referrer_id = u1.id) as current_referrals
FROM users u1
WHERE referrer_id IS NOT NULL 
  AND is_admin = false
  AND created_at < '2025-06-24 02:00:00'
ORDER BY created_at
LIMIT 20;

-- 4. 特定のユーザーグループの詳細確認
SELECT 
  'Specific Group Analysis' as check_type,
  user_id,
  name,
  email,
  phone,
  created_at,
  CASE 
    WHEN email LIKE '%@shogun-trade.com' THEN 'Internal Email'
    WHEN email LIKE '%gmail.com' THEN 'Gmail'
    WHEN email LIKE '%yahoo.co.jp' THEN 'Yahoo'
    ELSE 'Other'
  END as email_type
FROM users 
WHERE referrer_id IS NULL 
  AND is_admin = false
  AND created_at BETWEEN '2025-06-21 00:00:00' AND '2025-06-24 12:00:00'
ORDER BY created_at;

-- 5. 紹介コードの形式確認
SELECT 
  'Referral Code Format Check' as check_type,
  COUNT(*) as total_users,
  COUNT(CASE WHEN my_referral_code = user_id THEN 1 END) as matching_user_id,
  COUNT(CASE WHEN my_referral_code != user_id THEN 1 END) as different_format,
  COUNT(CASE WHEN my_referral_code IS NULL THEN 1 END) as null_referral_code
FROM users 
WHERE is_admin = false;
