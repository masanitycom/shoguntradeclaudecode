-- 包括的な検証と最終確認

-- 1. 全体的な紹介システムの健全性チェック
SELECT 
    'System Health Check' as check_type,
    COUNT(*) as total_users,
    COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) as users_with_referrer,
    COUNT(CASE WHEN id = referrer_id THEN 1 END) as self_referrals,
    COUNT(CASE WHEN referrer_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM users ref WHERE ref.id = users.referrer_id
    ) THEN 1 END) as invalid_referrer_ids,
    ROUND(AVG(CASE WHEN referrer_id IS NOT NULL THEN 1.0 ELSE 0.0 END) * 100, 2) as referrer_coverage_percent
FROM users 
WHERE is_admin = false;

-- 2. 日付の論理性チェック
SELECT 
    'Date Logic Check' as check_type,
    COUNT(*) as total_relationships,
    COUNT(CASE WHEN u.created_at > ref.created_at THEN 1 END) as logical_relationships,
    COUNT(CASE WHEN u.created_at <= ref.created_at THEN 1 END) as illogical_relationships,
    ROUND(
        COUNT(CASE WHEN u.created_at > ref.created_at THEN 1 END) * 100.0 / COUNT(*), 
        2
    ) as logical_percentage
FROM users u
JOIN users ref ON u.referrer_id = ref.id
WHERE u.is_admin = false;

-- 3. 紹介者分布の確認（修正後）
SELECT 
    'Referrer Distribution After Fix' as check_type,
    ref.user_id as referrer_code,
    ref.name as referrer_name,
    COUNT(u.id) as referral_count,
    ref.created_at as referrer_joined
FROM users u
JOIN users ref ON u.referrer_id = ref.id
WHERE u.is_admin = false
GROUP BY ref.id, ref.user_id, ref.name, ref.created_at
HAVING COUNT(u.id) > 0
ORDER BY referral_count DESC
LIMIT 20;

-- 4. 特定ユーザーの確認
SELECT 
    'Key Users Status' as check_type,
    u.user_id as user_code,
    u.name,
    ref.user_id as referrer_code,
    ref.name as referrer_name,
    COUNT(referred.id) as referral_count
FROM users u
LEFT JOIN users ref ON u.referrer_id = ref.id
LEFT JOIN users referred ON referred.referrer_id = u.id AND referred.is_admin = false
WHERE u.user_id IN ('1125Ritsuko', 'USER0a18', 'admin001')
GROUP BY u.id, u.user_id, u.name, ref.user_id, ref.name
ORDER BY u.user_id;

-- 5. 問題のあるケースの特定
SELECT 
    'Problem Cases' as check_type,
    'Issue Type' as category,
    COUNT(*) as count
FROM (
    SELECT 'Self Reference' as issue_type
    FROM users 
    WHERE id = referrer_id
    
    UNION ALL
    
    SELECT 'Missing Referrer' as issue_type
    FROM users 
    WHERE referrer_id IS NULL AND is_admin = false
    
    UNION ALL
    
    SELECT 'Invalid Referrer ID' as issue_type
    FROM users u
    WHERE referrer_id IS NOT NULL 
      AND NOT EXISTS (SELECT 1 FROM users ref WHERE ref.id = u.referrer_id)
      AND is_admin = false
    
    UNION ALL
    
    SELECT 'Date Logic Error' as issue_type
    FROM users u
    JOIN users ref ON u.referrer_id = ref.id
    WHERE u.created_at <= ref.created_at
      AND u.is_admin = false
) problem_summary
GROUP BY issue_type;

-- 6. 復元の成功度評価
WITH restoration_metrics AS (
    SELECT 
        COUNT(*) as total_users,
        COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) as users_with_referrer,
        COUNT(CASE WHEN id != referrer_id OR referrer_id IS NULL THEN 1 END) as non_self_referrals,
        COUNT(CASE WHEN referrer_id IS NOT NULL AND EXISTS (
            SELECT 1 FROM users ref WHERE ref.id = users.referrer_id
        ) THEN 1 END) as valid_referrer_ids
    FROM users 
    WHERE is_admin = false
)
SELECT 
    'Restoration Success Rate' as metric,
    ROUND(users_with_referrer * 100.0 / total_users, 2) as referrer_coverage_percent,
    ROUND(non_self_referrals * 100.0 / total_users, 2) as non_self_ref_percent,
    ROUND(valid_referrer_ids * 100.0 / total_users, 2) as valid_referrer_percent,
    CASE 
        WHEN users_with_referrer = total_users 
         AND non_self_referrals = total_users 
         AND valid_referrer_ids = total_users 
        THEN 'EXCELLENT'
        WHEN users_with_referrer * 100.0 / total_users > 95 THEN 'GOOD'
        WHEN users_with_referrer * 100.0 / total_users > 80 THEN 'ACCEPTABLE'
        ELSE 'NEEDS_WORK'
    END as overall_status
FROM restoration_metrics;
