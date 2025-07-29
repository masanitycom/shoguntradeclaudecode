-- バックアップ復元の検証と品質チェック

-- 1. バックアップとの整合性チェック
WITH backup_comparison AS (
    SELECT 
        u.user_id,
        u.name,
        u.referrer_id as current_referrer_id,
        ub.referrer_id as backup_referrer_id,
        current_ref.user_id as current_referrer_user_id,
        backup_ref_user.user_id as backup_referrer_user_id,
        CASE 
            WHEN u.referrer_id = ub.referrer_id THEN 'MATCH'
            WHEN u.referrer_id IS NULL AND ub.referrer_id IS NULL THEN 'BOTH_NULL'
            ELSE 'MISMATCH'
        END as status
    FROM users u
    LEFT JOIN users_backup ub ON u.user_id = ub.user_id
    LEFT JOIN users current_ref ON u.referrer_id = current_ref.id
    LEFT JOIN users_backup backup_ref ON ub.referrer_id = backup_ref.id
    LEFT JOIN users backup_ref_user ON backup_ref.user_id = backup_ref_user.user_id
    WHERE u.is_admin = false
)
SELECT 
    'Backup Consistency Check' as check_type,
    status,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM backup_comparison
GROUP BY status
ORDER BY count DESC;

-- 2. 特定の重要ケースの詳細確認
SELECT 
    'Critical Cases Verification' as check_type,
    u.user_id,
    u.name,
    current_ref.user_id as current_referrer,
    backup_ref_user.user_id as backup_referrer,
    CASE 
        WHEN current_ref.user_id = backup_ref_user.user_id THEN 'CORRECT'
        ELSE 'INCORRECT'
    END as status
FROM users u
LEFT JOIN users_backup ub ON u.user_id = ub.user_id
LEFT JOIN users current_ref ON u.referrer_id = current_ref.id
LEFT JOIN users_backup backup_ref ON ub.referrer_id = backup_ref.id
LEFT JOIN users backup_ref_user ON backup_ref.user_id = backup_ref_user.user_id
WHERE u.user_id IN ('1125Ritsuko', 'USER0a18', 'bighand1011', 'Mira', 'admin001')
ORDER BY u.user_id;

-- 3. 日付の論理性チェック（復元後）
SELECT 
    'Date Logic After Restoration' as check_type,
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

-- 4. 循環参照チェック（復元後）
WITH RECURSIVE referral_chain AS (
    -- 開始点
    SELECT 
        id as user_id,
        user_id as user_code,
        referrer_id,
        1 as depth,
        ARRAY[id] as path
    FROM users 
    WHERE is_admin = false
    
    UNION ALL
    
    -- 再帰部分
    SELECT 
        rc.user_id,
        rc.user_code,
        u.referrer_id,
        rc.depth + 1,
        rc.path || u.id
    FROM referral_chain rc
    JOIN users u ON rc.referrer_id = u.id
    WHERE rc.depth < 10  -- 無限ループ防止
      AND u.id != ALL(rc.path)  -- 循環検出
      AND u.referrer_id IS NOT NULL
)
SELECT 
    'Circular Reference Check After Restoration' as check_type,
    COUNT(DISTINCT user_id) as users_in_potential_cycles,
    MAX(depth) as max_chain_depth
FROM referral_chain
WHERE depth > 5;

-- 5. 復元品質スコア
WITH quality_metrics AS (
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
    'Restoration Quality Score' as metric,
    ROUND(users_with_referrer * 100.0 / total_users, 2) as referrer_coverage_percent,
    ROUND(non_self_referrals * 100.0 / total_users, 2) as non_self_ref_percent,
    ROUND(valid_referrer_ids * 100.0 / total_users, 2) as valid_referrer_percent,
    CASE 
        WHEN users_with_referrer = total_users 
         AND non_self_referrals = total_users 
         AND valid_referrer_ids = total_users 
        THEN 'PERFECT'
        WHEN users_with_referrer * 100.0 / total_users > 95 THEN 'EXCELLENT'
        WHEN users_with_referrer * 100.0 / total_users > 80 THEN 'GOOD'
        ELSE 'NEEDS_IMPROVEMENT'
    END as overall_quality
FROM quality_metrics;
