-- 修正された登録システムのテスト

-- 1. 整合性チェックの実行
SELECT * FROM check_referral_integrity();

-- 2. 修正後の統計
SELECT 
  'Final Statistics' as check_type,
  COUNT(*) as total_users,
  COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) as users_with_referrer,
  COUNT(CASE WHEN my_referral_code = user_id THEN 1 END) as correct_referral_codes,
  COUNT(CASE WHEN referral_link LIKE '%' || user_id THEN 1 END) as correct_referral_links,
  COUNT(DISTINCT referrer_id) as unique_referrers,
  ROUND(AVG((SELECT COUNT(*) FROM users u2 WHERE u2.referrer_id = u1.referrer_id)), 2) as avg_referrals_per_referrer
FROM users u1
WHERE is_admin = false;

-- 3. 紹介関係の分布確認
SELECT 
  'Referral Distribution' as check_type,
  referral_count,
  COUNT(*) as referrers_with_this_count
FROM (
  SELECT 
    u2.user_id,
    COUNT(u1.id) as referral_count
  FROM users u2
  LEFT JOIN users u1 ON u1.referrer_id = u2.id AND u1.is_admin = false
  WHERE u2.is_admin = false
  GROUP BY u2.id, u2.user_id
) referral_counts
GROUP BY referral_count
ORDER BY referral_count;

-- 4. 最新の紹介者ランキング
SELECT 
  'Top 20 Referrers' as check_type,
  u2.user_id as referrer_user_id,
  u2.name as referrer_name,
  COUNT(u1.id) as total_referrals,
  u2.created_at as referrer_joined
FROM users u1
JOIN users u2 ON u1.referrer_id = u2.id
WHERE u1.is_admin = false
GROUP BY u2.id, u2.user_id, u2.name, u2.created_at
ORDER BY total_referrals DESC, u2.created_at ASC
LIMIT 20;

-- 5. 問題のあるケースの最終チェック
SELECT 
  'Problem Cases Check' as check_type,
  'Self referrals' as issue_type,
  COUNT(*) as count
FROM users 
WHERE id = referrer_id

UNION ALL

SELECT 
  'Problem Cases Check' as check_type,
  'Missing referrer' as issue_type,
  COUNT(*) as count
FROM users 
WHERE referrer_id IS NULL AND is_admin = false

UNION ALL

SELECT 
  'Problem Cases Check' as check_type,
  'Invalid referral codes' as issue_type,
  COUNT(*) as count
FROM users 
WHERE my_referral_code != user_id AND is_admin = false

UNION ALL

SELECT 
  'Problem Cases Check' as check_type,
  'Missing referral links' as issue_type,
  COUNT(*) as count
FROM users 
WHERE referral_link IS NULL AND is_admin = false;
