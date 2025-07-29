-- バックアップの完全性分析

-- 1. 基本統計
WITH backup_stats AS (
    SELECT 
        COUNT(*) as current_users,
        (SELECT COUNT(*) FROM users_backup) as backup_users,
        COUNT(*) - (SELECT COUNT(*) FROM users_backup) as missing_from_backup
    FROM users 
    WHERE is_admin = false
)
SELECT 
    'User Count Comparison' as analysis_type,
    current_users,
    backup_users,
    missing_from_backup
FROM backup_stats;

-- 2. バックアップに含まれていないユーザー（最初の50人）
SELECT 
    'Missing from Backup' as analysis_type,
    u.user_id,
    u.name,
    u.email,
    u.created_at,
    ref.user_id as current_referrer,
    ref.name as current_referrer_name
FROM users u
LEFT JOIN users ref ON u.referrer_id = ref.id
WHERE u.is_admin = false
  AND NOT EXISTS (SELECT 1 FROM users_backup ub WHERE ub.user_id = u.user_id)
ORDER BY u.created_at
LIMIT 50;

-- 3. バックアップにあるが現在のDBにないユーザー
SELECT 
    'In Backup but Missing from Current' as analysis_type,
    ub.user_id,
    ub.name,
    ub.email,
    ub.created_at
FROM users_backup ub
WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.user_id = ub.user_id)
ORDER BY ub.created_at;

-- 4. 重要ユーザーのバックアップ状況
SELECT 
    'Critical Users Backup Status' as analysis_type,
    u.user_id,
    u.name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM users_backup ub WHERE ub.user_id = u.user_id) 
        THEN 'IN_BACKUP' 
        ELSE 'NOT_IN_BACKUP' 
    END as backup_status,
    u.created_at,
    COUNT(referred.id) as current_referrals
FROM users u
LEFT JOIN users referred ON referred.referrer_id = u.id AND referred.is_admin = false
WHERE u.user_id IN ('1125Ritsuko', 'USER0a18', 'bighand1011', 'Mira', 'admin001')
GROUP BY u.id, u.user_id, u.name, u.created_at
ORDER BY u.user_id;

-- 5. バックアップの日付範囲
SELECT 
    'Backup Date Range' as analysis_type,
    MIN(created_at) as earliest_user,
    MAX(created_at) as latest_user,
    COUNT(*) as total_users,
    COUNT(CASE WHEN created_at >= '2025-06-24' THEN 1 END) as users_after_june_24
FROM users_backup;

-- 6. 現在のDBの日付範囲
SELECT 
    'Current DB Date Range' as analysis_type,
    MIN(created_at) as earliest_user,
    MAX(created_at) as latest_user,
    COUNT(*) as total_users,
    COUNT(CASE WHEN created_at >= '2025-06-24' THEN 1 END) as users_after_june_24
FROM users 
WHERE is_admin = false;
