-- 緊急：紹介者データの整合性チェック

-- 1. 紹介者がいないユーザーの緊急リスト（重要度順）
SELECT 
  'URGENT: Missing Referrers' as priority,
  user_id,
  name,
  email,
  phone,
  created_at,
  CASE 
    WHEN created_at < '2025-06-22 00:00:00' THEN 'CRITICAL - Early User'
    WHEN created_at < '2025-06-24 00:00:00' THEN 'HIGH - Mid Period'
    ELSE 'MEDIUM - Recent'
  END as urgency_level,
  CASE 
    WHEN email LIKE '%@shogun-trade.com' THEN 'Internal (Temp Email)'
    ELSE 'External User'
  END as user_type
FROM users 
WHERE referrer_id IS NULL 
  AND is_admin = false
ORDER BY 
  CASE 
    WHEN created_at < '2025-06-22 00:00:00' THEN 1
    WHEN created_at < '2025-06-24 00:00:00' THEN 2
    ELSE 3
  END,
  created_at;

-- 2. 削除された可能性のある紹介者の確認
SELECT 
  'Potential Deleted Referrers Check' as check_type,
  'Checking for orphaned referrer_id values' as description,
  COUNT(*) as total_users_checked
FROM users 
WHERE is_admin = false;

-- 3. auth.usersとpublic.usersの同期状況
SELECT 
  'Auth Sync Status' as check_type,
  COUNT(au.id) as auth_users,
  COUNT(pu.id) as public_users,
  COUNT(CASE WHEN au.id IS NOT NULL AND pu.id IS NOT NULL THEN 1 END) as synced_users,
  COUNT(CASE WHEN au.id IS NOT NULL AND pu.id IS NULL THEN 1 END) as auth_only,
  COUNT(CASE WHEN au.id IS NULL AND pu.id IS NOT NULL THEN 1 END) as public_only
FROM auth.users au
FULL OUTER JOIN public.users pu ON au.id = pu.id
WHERE au.email NOT LIKE '%@supabase%' OR au.email IS NULL;

-- 4. 紹介システムの基本統計
SELECT 
  'Referral System Health Check' as check_type,
  (SELECT COUNT(*) FROM users WHERE is_admin = false) as total_regular_users,
  (SELECT COUNT(*) FROM users WHERE is_admin = false AND referrer_id IS NOT NULL) as users_with_referrer,
  (SELECT COUNT(*) FROM users WHERE is_admin = false AND referrer_id IS NULL) as users_without_referrer,
  (SELECT COUNT(DISTINCT referrer_id) FROM users WHERE referrer_id IS NOT NULL) as active_referrers,
  (SELECT AVG(referral_count) FROM (
    SELECT COUNT(*) as referral_count 
    FROM users 
    WHERE referrer_id IS NOT NULL 
    GROUP BY referrer_id
  ) sub) as avg_referrals_per_referrer;
