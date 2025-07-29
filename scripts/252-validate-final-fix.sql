-- 最終検証とクリーンアップ

-- 1. 全体的な整合性チェック
SELECT 
    'Final Validation' as check_type,
    COUNT(*) as total_users,
    COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) as users_with_referrer,
    COUNT(CASE WHEN referrer_id IS NULL THEN 1 END) as users_without_referrer,
    COUNT(CASE WHEN id = referrer_id THEN 1 END) as self_referrals,
    COUNT(CASE WHEN my_referral_code = user_id THEN 1 END) as correct_referral_codes,
    COUNT(CASE WHEN my_referral_code IS NULL OR my_referral_code != user_id THEN 1 END) as incorrect_referral_codes,
    ROUND(COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) as referrer_percentage
FROM users 
WHERE is_admin = false;

-- 2. 循環参照の最終チェック（簡易版）
WITH RECURSIVE simple_cycle_check AS (
    SELECT 
        id,
        referrer_id,
        1 as depth,
        ARRAY[id] as path
    FROM users 
    WHERE is_admin = false
    
    UNION ALL
    
    SELECT 
        scc.id,
        u.referrer_id,
        scc.depth + 1,
        scc.path || u.id
    FROM simple_cycle_check scc
    JOIN users u ON scc.referrer_id = u.id
    WHERE scc.depth < 5 
      AND NOT u.id = ANY(scc.path)
      AND u.referrer_id IS NOT NULL
)
SELECT 
    'Cycle Check Results' as check_type,
    COUNT(DISTINCT id) as users_checked,
    COUNT(CASE WHEN depth > 3 THEN 1 END) as potential_long_chains
FROM simple_cycle_check;

-- 3. 紹介者分布の確認
SELECT 
    'Referrer Distribution' as check_type,
    referral_count,
    COUNT(*) as referrers_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
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

-- 4. トップ紹介者の再確認（修正後）
SELECT 
    'Top Referrers After Fix' as check_type,
    u2.user_id as referrer_user_id,
    u2.name as referrer_name,
    COUNT(u1.id) as total_referrals,
    u2.created_at as referrer_joined,
    CASE 
        WHEN u2.id = u2.referrer_id THEN 'SELF_REF'
        WHEN u2.referrer_id IS NULL THEN 'NO_REF'
        ELSE 'OK'
    END as referrer_status
FROM users u1
JOIN users u2 ON u1.referrer_id = u2.id
WHERE u1.is_admin = false
GROUP BY u2.id, u2.user_id, u2.name, u2.created_at, u2.referrer_id
ORDER BY total_referrals DESC
LIMIT 10;

-- 5. 問題ケースの最終確認
SELECT 
    'Problem Cases Final Check' as check_type,
    'Self referrals' as issue_type,
    COUNT(*) as count
FROM users 
WHERE id = referrer_id

UNION ALL

SELECT 
    'Problem Cases Final Check' as check_type,
    'Missing referrer' as issue_type,
    COUNT(*) as count
FROM users 
WHERE referrer_id IS NULL AND is_admin = false

UNION ALL

SELECT 
    'Problem Cases Final Check' as check_type,
    'Invalid referral codes' as issue_type,
    COUNT(*) as count
FROM users 
WHERE (my_referral_code != user_id OR my_referral_code IS NULL) AND is_admin = false

UNION ALL

SELECT 
    'Problem Cases Final Check' as check_type,
    'Orphaned referrers' as issue_type,
    COUNT(*) as count
FROM users u1
LEFT JOIN users u2 ON u1.referrer_id = u2.id
WHERE u1.referrer_id IS NOT NULL 
  AND u2.id IS NULL 
  AND u1.is_admin = false;
