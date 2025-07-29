-- 復元されたデータの品質検証

-- 1. 復元結果の詳細確認
SELECT 
  'Restoration Summary' as check_type,
  COUNT(*) as total_users,
  COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) as users_with_referrer,
  COUNT(CASE WHEN referrer_id IS NULL THEN 1 END) as users_without_referrer,
  COUNT(DISTINCT referrer_id) as unique_referrers,
  ROUND(AVG((SELECT COUNT(*) FROM users u2 WHERE u2.referrer_id = u1.referrer_id)), 2) as avg_referrals_per_referrer
FROM users u1
WHERE is_admin = false;

-- 2. 紹介者として最も多く使われているユーザー
SELECT 
  'Top Referrers After Restoration' as check_type,
  u2.user_id as referrer_user_id,
  u2.name as referrer_name,
  u2.email as referrer_email,
  u2.created_at as referrer_created,
  COUNT(u1.id) as total_referrals
FROM users u1
JOIN users u2 ON u1.referrer_id = u2.id
WHERE u1.is_admin = false
GROUP BY u2.id, u2.user_id, u2.name, u2.email, u2.created_at
ORDER BY total_referrals DESC
LIMIT 10;

-- 3. 紹介関係の循環参照チェック
WITH RECURSIVE referral_chain AS (
  -- 開始点
  SELECT id, user_id, referrer_id, 1 as depth, ARRAY[id] as path
  FROM users 
  WHERE is_admin = false
  
  UNION ALL
  
  -- 再帰部分
  SELECT u.id, u.user_id, u.referrer_id, rc.depth + 1, rc.path || u.id
  FROM users u
  JOIN referral_chain rc ON u.id = rc.referrer_id
  WHERE rc.depth < 10 AND NOT u.id = ANY(rc.path)
)
SELECT 
  'Circular Reference Check' as check_type,
  COUNT(*) as potential_circular_refs
FROM referral_chain 
WHERE depth > 5;

-- 4. 自分自身を紹介者にしているユーザーチェック
SELECT 
  'Self Referral Check' as check_type,
  user_id,
  name,
  email
FROM users 
WHERE id = referrer_id;

-- 5. 紹介者の登録日が被紹介者より後のケース
SELECT 
  'Invalid Date Order Check' as check_type,
  u1.user_id as referred_user,
  u1.name as referred_name,
  u1.created_at as referred_date,
  u2.user_id as referrer_user,
  u2.name as referrer_name,
  u2.created_at as referrer_date,
  EXTRACT(EPOCH FROM (u1.created_at - u2.created_at))/3600 as hours_diff
FROM users u1
JOIN users u2 ON u1.referrer_id = u2.id
WHERE u1.created_at < u2.created_at
  AND u1.is_admin = false
ORDER BY hours_diff DESC
LIMIT 20;

-- 6. 紹介リンクの整合性確認
SELECT 
  'Referral Link Consistency' as check_type,
  COUNT(*) as total_users,
  COUNT(CASE WHEN my_referral_code = user_id THEN 1 END) as correct_referral_codes,
  COUNT(CASE WHEN referral_link LIKE '%' || user_id THEN 1 END) as correct_referral_links,
  COUNT(CASE WHEN my_referral_code IS NULL THEN 1 END) as null_referral_codes,
  COUNT(CASE WHEN referral_link IS NULL THEN 1 END) as null_referral_links
FROM users 
WHERE is_admin = false;
