-- バックアップデータに基づく安全な部分修正の特定

-- 1. バックアップに存在し、明らかに間違っている紹介関係を特定
WITH backup_matches AS (
    SELECT 
        u.id as current_id,
        u.user_id,
        u.name,
        u.referrer_id as current_referrer_id,
        current_ref.user_id as current_referrer_code,
        ub.referrer_id as backup_referrer_id,
        backup_ref.user_id as backup_referrer_code,
        target_ref.id as target_referrer_id
    FROM users u
    JOIN users_backup ub ON u.user_id = ub.user_id
    LEFT JOIN users current_ref ON u.referrer_id = current_ref.id
    LEFT JOIN users_backup backup_ref ON ub.referrer_id = backup_ref.id
    LEFT JOIN users target_ref ON backup_ref.user_id = target_ref.user_id
    WHERE u.is_admin = false
      AND ub.referrer_id IS NOT NULL
      AND backup_ref.user_id IS NOT NULL
      AND target_ref.id IS NOT NULL
      AND u.referrer_id != target_ref.id
)
SELECT 
    'Safe Fixes Available' as analysis_type,
    user_id,
    name,
    current_referrer_code,
    backup_referrer_code,
    CASE 
        WHEN current_referrer_code IS NULL THEN 'MISSING_REFERRER'
        WHEN current_referrer_code != backup_referrer_code THEN 'WRONG_REFERRER'
        ELSE 'OTHER'
    END as issue_type
FROM backup_matches
ORDER BY user_id;

-- 2. 高優先度修正対象（多くの紹介者を持つユーザー）
WITH referral_counts AS (
    SELECT 
        u.id,
        u.user_id,
        u.name,
        COUNT(referred.id) as referral_count
    FROM users u
    LEFT JOIN users referred ON referred.referrer_id = u.id AND referred.is_admin = false
    GROUP BY u.id, u.user_id, u.name
),
backup_fixes AS (
    SELECT 
        u.user_id,
        u.name,
        current_ref.user_id as current_referrer,
        backup_ref.user_id as backup_referrer,
        rc.referral_count
    FROM users u
    JOIN users_backup ub ON u.user_id = ub.user_id
    LEFT JOIN users current_ref ON u.referrer_id = current_ref.id
    LEFT JOIN users_backup backup_ref ON ub.referrer_id = backup_ref.id
    LEFT JOIN referral_counts rc ON u.id = rc.id
    WHERE u.is_admin = false
      AND (current_ref.user_id != backup_ref.user_id OR current_ref.user_id IS NULL)
      AND backup_ref.user_id IS NOT NULL
      AND EXISTS (SELECT 1 FROM users target WHERE target.user_id = backup_ref.user_id)
)
SELECT 
    'High Priority Fixes' as analysis_type,
    user_id,
    name,
    current_referrer,
    backup_referrer,
    COALESCE(referral_count, 0) as referral_count,
    CASE 
        WHEN referral_count > 10 THEN 'CRITICAL'
        WHEN referral_count > 5 THEN 'HIGH'
        WHEN referral_count > 0 THEN 'MEDIUM'
        ELSE 'LOW'
    END as priority
FROM backup_fixes
ORDER BY COALESCE(referral_count, 0) DESC, user_id;

-- 3. 新規ユーザー（バックアップ後に追加）の処理方針
SELECT 
    'New Users After Backup' as analysis_type,
    u.user_id,
    u.name,
    u.created_at,
    ref.user_id as current_referrer,
    CASE 
        WHEN u.created_at > (SELECT MAX(created_at) FROM users_backup) THEN 'AFTER_BACKUP'
        ELSE 'SHOULD_BE_IN_BACKUP'
    END as status,
    CASE 
        WHEN ref.id IS NULL THEN 'NEEDS_REFERRER'
        WHEN ref.id = u.id THEN 'SELF_REFERENCE'
        ELSE 'HAS_REFERRER'
    END as referrer_status
FROM users u
LEFT JOIN users ref ON u.referrer_id = ref.id
WHERE u.is_admin = false
  AND NOT EXISTS (SELECT 1 FROM users_backup ub WHERE ub.user_id = u.user_id)
ORDER BY u.created_at;

-- 4. 修正実行の安全性評価
WITH safety_check AS (
    SELECT 
        COUNT(*) as total_users,
        COUNT(CASE WHEN EXISTS (SELECT 1 FROM users_backup ub WHERE ub.user_id = users.user_id) THEN 1 END) as in_backup,
        COUNT(CASE WHEN referrer_id IS NULL THEN 1 END) as no_referrer,
        COUNT(CASE WHEN id = referrer_id THEN 1 END) as self_reference
    FROM users 
    WHERE is_admin = false
)
SELECT 
    'Safety Assessment' as analysis_type,
    total_users,
    in_backup,
    total_users - in_backup as not_in_backup,
    ROUND(in_backup * 100.0 / total_users, 2) as backup_coverage_percent,
    no_referrer,
    self_reference,
    CASE 
        WHEN in_backup * 100.0 / total_users > 90 THEN 'SAFE_FOR_FULL_RESTORE'
        WHEN in_backup * 100.0 / total_users > 70 THEN 'SAFE_FOR_PARTIAL_RESTORE'
        ELSE 'ONLY_TARGETED_FIXES'
    END as recommendation
FROM safety_check;
