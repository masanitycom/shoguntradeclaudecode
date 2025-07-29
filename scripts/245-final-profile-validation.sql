-- 最終的なプロフィール検証

-- 1. 全ユーザーのプロフィール完全性チェック
WITH profile_completeness AS (
  SELECT 
    user_id,
    name,
    email,
    phone,
    referrer_id,
    my_referral_code,
    referral_link,
    CASE WHEN referrer_id IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN phone IS NOT NULL AND phone != '' THEN 1 ELSE 0 END +
    CASE WHEN my_referral_code IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN referral_link IS NOT NULL THEN 1 ELSE 0 END as completeness_score
  FROM users 
  WHERE is_admin = false
)
SELECT 
  'Profile Completeness Distribution' as check_type,
  completeness_score,
  COUNT(*) as user_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM profile_completeness
GROUP BY completeness_score
ORDER BY completeness_score DESC;

-- 2. 特定の重要ユーザーの最終確認
SELECT 
  'Important Users Final Check' as check_type,
  user_id,
  name,
  email,
  phone,
  CASE WHEN referrer_id IS NOT NULL THEN 'OK' ELSE 'MISSING' END as referrer_status,
  CASE WHEN my_referral_code IS NOT NULL THEN 'OK' ELSE 'MISSING' END as referral_code_status,
  CASE WHEN referral_link IS NOT NULL THEN 'OK' ELSE 'MISSING' END as referral_link_status
FROM users 
WHERE user_id IN (
  'Tomo115', '0619mmmk', 'mook0214', 
  '1125Ritsuko', '403704mi', 'bighand1011',
  'USER001', 'USER002', 'USER003'
)
ORDER BY user_id;

-- 3. システム全体の健全性確認
SELECT 
  'System Health Check' as check_type,
  'Total Users' as metric,
  COUNT(*) as value
FROM users WHERE is_admin = false

UNION ALL

SELECT 
  'System Health Check' as check_type,
  'Complete Profiles' as metric,
  COUNT(*) as value
FROM users 
WHERE is_admin = false
  AND referrer_id IS NOT NULL
  AND phone IS NOT NULL 
  AND phone != ''
  AND my_referral_code IS NOT NULL
  AND referral_link IS NOT NULL

UNION ALL

SELECT 
  'System Health Check' as check_type,
  'Admin Users' as metric,
  COUNT(*) as value
FROM users WHERE is_admin = true;
