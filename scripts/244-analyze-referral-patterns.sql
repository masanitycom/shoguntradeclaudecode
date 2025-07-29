-- 紹介パターンの分析

-- 1. 実際に紹介者がいるユーザーの紹介関係を確認
WITH referral_analysis AS (
  SELECT 
    u1.user_id as referred_user,
    u1.name as referred_name,
    u1.my_referral_code as used_referral_code,
    u2.user_id as referrer_user_id,
    u2.name as referrer_name,
    u2.my_referral_code as referrer_code,
    u1.created_at as referred_time,
    u2.created_at as referrer_time
  FROM users u1
  LEFT JOIN users u2 ON u1.referrer_id = u2.id
  WHERE u1.referrer_id IS NOT NULL 
    AND u1.is_admin = false
)
SELECT 
  'Working Referral Patterns' as check_type,
  *
FROM referral_analysis
ORDER BY referred_time
LIMIT 20;

-- 2. 紹介コードの使用状況
SELECT 
  'Referral Code Usage' as check_type,
  u2.user_id as referrer_user_id,
  u2.name as referrer_name,
  u2.my_referral_code as referral_code,
  COUNT(u1.id) as total_referrals,
  MIN(u1.created_at) as first_referral,
  MAX(u1.created_at) as last_referral
FROM users u1
JOIN users u2 ON u1.referrer_id = u2.id
WHERE u1.is_admin = false
GROUP BY u2.id, u2.user_id, u2.name, u2.my_referral_code
ORDER BY total_referrals DESC;

-- 3. 紹介者なしユーザーの中で、実際は紹介関係があるべきユーザーを特定
SELECT 
  'Missing Referrer Analysis' as check_type,
  no_ref.user_id,
  no_ref.name,
  no_ref.email,
  no_ref.my_referral_code,
  no_ref.created_at,
  -- 同じ紹介コードを使っている他のユーザーがいるかチェック
  (SELECT COUNT(*) FROM users u2 
   WHERE u2.my_referral_code = no_ref.my_referral_code 
   AND u2.referrer_id IS NOT NULL) as others_with_same_code,
  -- 同じ紹介コードを使っている他のユーザーの紹介者
  (SELECT DISTINCT u3.user_id FROM users u2 
   JOIN users u3 ON u2.referrer_id = u3.id
   WHERE u2.my_referral_code = no_ref.my_referral_code 
   AND u2.referrer_id IS NOT NULL
   LIMIT 1) as should_be_referrer
FROM users no_ref
WHERE no_ref.referrer_id IS NULL 
  AND no_ref.is_admin = false
  AND no_ref.my_referral_code IS NOT NULL
ORDER BY no_ref.created_at
LIMIT 30;
