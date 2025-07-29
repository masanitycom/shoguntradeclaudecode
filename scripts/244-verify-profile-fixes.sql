-- プロフィール修正の検証

-- 1. 修正前後の比較
SELECT 
  'Before/After Comparison' as check_type,
  'Total Users' as metric,
  COUNT(*) as count
FROM users 
WHERE is_admin = false

UNION ALL

SELECT 
  'Before/After Comparison' as check_type,
  'Users with Referrer' as metric,
  COUNT(*) as count
FROM users 
WHERE is_admin = false 
  AND referrer_id IS NOT NULL

UNION ALL

SELECT 
  'Before/After Comparison' as check_type,
  'Users with Phone' as metric,
  COUNT(*) as count
FROM users 
WHERE is_admin = false 
  AND phone IS NOT NULL 
  AND phone != ''

UNION ALL

SELECT 
  'Before/After Comparison' as check_type,
  'Users with Referral Code' as metric,
  COUNT(*) as count
FROM users 
WHERE is_admin = false 
  AND my_referral_code IS NOT NULL;

-- 2. 問題のあるユーザーの残存確認
SELECT 
  'Remaining Issues' as check_type,
  user_id,
  name,
  email,
  phone,
  referrer_id,
  my_referral_code,
  'Missing: ' || 
  CASE 
    WHEN referrer_id IS NULL THEN 'Referrer '
    ELSE ''
  END ||
  CASE 
    WHEN phone IS NULL OR phone = '' THEN 'Phone '
    ELSE ''
  END ||
  CASE 
    WHEN my_referral_code IS NULL THEN 'ReferralCode '
    ELSE ''
  END as missing_fields
FROM users 
WHERE is_admin = false
  AND (
    referrer_id IS NULL OR 
    phone IS NULL OR 
    phone = '' OR 
    my_referral_code IS NULL
  )
ORDER BY user_id
LIMIT 10;

-- 3. 紹介関係の整合性確認
SELECT 
  'Referral System Check' as check_type,
  COUNT(DISTINCT u.referrer_id) as unique_referrers,
  COUNT(*) as total_referred_users,
  AVG(referred_count.count) as avg_referrals_per_referrer
FROM users u
JOIN (
  SELECT referrer_id, COUNT(*) as count
  FROM users 
  WHERE referrer_id IS NOT NULL
  GROUP BY referrer_id
) referred_count ON u.referrer_id = referred_count.referrer_id
WHERE u.is_admin = false;
