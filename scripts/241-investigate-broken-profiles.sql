-- 1. 紹介者がいないユーザーの調査
SELECT 
  'No Referrer Users' as check_type,
  user_id,
  name,
  email,
  referrer_id,
  created_at,
  CASE 
    WHEN name LIKE '%@%' THEN 'Email-based name'
    WHEN name = SPLIT_PART(email, '@', 1) THEN 'Email prefix name'
    ELSE 'Normal name'
  END as name_status
FROM users 
WHERE referrer_id IS NULL 
  AND is_admin = false
ORDER BY created_at
LIMIT 20;

-- 2. 特定ユーザーの詳細確認
SELECT 
  'Specific Users Check' as check_type,
  user_id,
  name,
  email,
  phone,
  referrer_id,
  my_referral_code,
  referral_link,
  created_at
FROM users 
WHERE user_id IN ('Tomo115', '0619mmmk', 'mook0214')
ORDER BY user_id;

-- 3. 名前がメールアドレスベースのユーザー統計
SELECT 
  'Name Issues Statistics' as check_type,
  COUNT(*) as total_users,
  COUNT(CASE WHEN referrer_id IS NULL THEN 1 END) as no_referrer,
  COUNT(CASE WHEN name = SPLIT_PART(email, '@', 1) THEN 1 END) as email_prefix_names,
  COUNT(CASE WHEN name LIKE '%@%' THEN 1 END) as email_based_names,
  COUNT(CASE WHEN phone IS NULL OR phone = '' THEN 1 END) as no_phone
FROM users 
WHERE is_admin = false;

-- 4. auth.users と public.users の同期状況確認
SELECT 
  'Auth Sync Check' as check_type,
  au.id as auth_id,
  au.email as auth_email,
  au.raw_user_meta_data,
  pu.id as public_id,
  pu.email as public_email,
  pu.name as public_name,
  pu.user_id as public_user_id
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.referrer_id IS NULL 
  AND pu.is_admin = false
ORDER BY au.created_at
LIMIT 10;

-- 5. 不完全なプロフィールの詳細分析
SELECT 
  'Incomplete Profiles' as check_type,
  user_id,
  name,
  email,
  phone,
  referrer_id,
  CASE 
    WHEN phone IS NULL OR phone = '' THEN 'No phone'
    ELSE 'Has phone'
  END as phone_status,
  CASE 
    WHEN name = SPLIT_PART(email, '@', 1) THEN 'Email prefix'
    WHEN name LIKE '%@%' THEN 'Full email'
    ELSE 'Normal'
  END as name_type,
  created_at
FROM users 
WHERE referrer_id IS NULL 
  AND is_admin = false
  AND (
    phone IS NULL OR 
    phone = '' OR 
    name = SPLIT_PART(email, '@', 1) OR
    name LIKE '%@%'
  )
ORDER BY created_at;
