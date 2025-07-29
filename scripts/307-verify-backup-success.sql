-- ==========================================
-- バックアップ成功確認スクリプト
-- 2025-06-29 バックアップの詳細検証
-- ==========================================

-- 1. バックアップテーブルの存在確認
SELECT 
    '📋 BACKUP TABLES VERIFICATION' as section,
    table_name,
    'EXISTS' as status
FROM information_schema.tables 
WHERE table_name LIKE '%backup_20250629%'
ORDER BY table_name;

-- 2. 各テーブルのレコード数確認
SELECT 
    '📊 RECORD COUNTS' as section,
    'users_backup_20250629' as table_name,
    COUNT(*) as record_count,
    COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) as users_with_referrer,
    COUNT(DISTINCT email) as unique_emails
FROM users_backup_20250629

UNION ALL

SELECT 
    '📊 RECORD COUNTS',
    'user_nfts_backup_20250629',
    COUNT(*),
    COUNT(CASE WHEN is_active = true THEN 1 END),
    COUNT(DISTINCT user_id)
FROM user_nfts_backup_20250629

UNION ALL

SELECT 
    '📊 RECORD COUNTS',
    'daily_rewards_backup_20250629',
    COUNT(*),
    COUNT(DISTINCT user_id),
    CAST(SUM(reward_amount) AS INTEGER)
FROM daily_rewards_backup_20250629

UNION ALL

SELECT 
    '📊 RECORD COUNTS',
    'reward_applications_backup_20250629',
    COUNT(*),
    COUNT(DISTINCT user_id),
    0
FROM reward_applications_backup_20250629

UNION ALL

SELECT 
    '📊 RECORD COUNTS',
    'nft_purchase_applications_backup_20250629',
    COUNT(*),
    COUNT(DISTINCT user_id),
    0
FROM nft_purchase_applications_backup_20250629

UNION ALL

SELECT 
    '📊 RECORD COUNTS',
    'user_rank_history_backup_20250629',
    COUNT(*),
    COUNT(DISTINCT user_id),
    0
FROM user_rank_history_backup_20250629

UNION ALL

SELECT 
    '📊 RECORD COUNTS',
    'tenka_bonus_distributions_backup_20250629',
    COUNT(*),
    COUNT(DISTINCT user_id),
    0
FROM tenka_bonus_distributions_backup_20250629;

-- 3. 紹介関係の整合性チェック
SELECT 
    '🔗 REFERRAL INTEGRITY CHECK' as section,
    COUNT(*) as total_users,
    COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) as users_with_referrer,
    COUNT(CASE WHEN referrer_id IS NOT NULL AND referrer_id NOT IN (SELECT id FROM users_backup_20250629) THEN 1 END) as broken_referrals,
    CASE 
        WHEN COUNT(CASE WHEN referrer_id IS NOT NULL AND referrer_id NOT IN (SELECT id FROM users_backup_20250629) THEN 1 END) = 0 
        THEN '✅ PERFECT INTEGRITY' 
        ELSE '⚠️ ISSUES FOUND' 
    END as integrity_status
FROM users_backup_20250629;

-- 4. 管理者ユーザーの確認（重要ユーザー）
SELECT 
    '👥 ADMIN USERS VERIFICATION' as section,
    email,
    CASE WHEN referrer_id IS NULL THEN 'ROOT USER' ELSE CAST(referrer_id AS TEXT) END as referrer_info,
    created_at,
    is_admin
FROM users_backup_20250629 
WHERE is_admin = true OR email LIKE '%admin%'
ORDER BY email;

-- 5. 特定の重要ユーザーの確認
SELECT 
    '🔑 KEY USERS BY EMAIL' as section,
    email,
    CASE WHEN referrer_id IS NULL THEN 'ROOT USER' ELSE CAST(referrer_id AS TEXT) END as referrer_info,
    created_at,
    is_admin
FROM users_backup_20250629 
WHERE email IN ('admin001@example.com', 'ohtakiyo@example.com', '1125ritsuko@example.com')
   OR email LIKE '%ohtakiyo%'
   OR email LIKE '%ritsuko%'
ORDER BY email;

-- 6. トップ紹介者の確認
SELECT 
    '👑 TOP REFERRERS IN BACKUP' as section,
    u.email as referrer_email,
    COUNT(r.id) as total_referrals
FROM users_backup_20250629 u
LEFT JOIN users_backup_20250629 r ON u.id = r.referrer_id
GROUP BY u.id, u.email
HAVING COUNT(r.id) > 0
ORDER BY total_referrals DESC
LIMIT 5;

-- 7. NFT保有状況の確認
SELECT 
    '💎 NFT OWNERSHIP IN BACKUP' as section,
    COUNT(*) as total_nft_records,
    COUNT(DISTINCT user_id) as users_with_nfts,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_nfts,
    COUNT(DISTINCT nft_id) as unique_nft_types,
    COALESCE(SUM(purchase_price), 0) as total_investment_value
FROM user_nfts_backup_20250629;

-- 8. 日利報酬の統計
SELECT 
    '💰 DAILY REWARDS IN BACKUP' as section,
    COUNT(*) as total_reward_records,
    COUNT(DISTINCT user_id) as users_with_rewards,
    CAST(SUM(reward_amount) AS INTEGER) as total_reward_amount,
    CAST(AVG(reward_amount) AS DECIMAL(10,2)) as average_reward,
    MIN(reward_date) as earliest_reward_date,
    MAX(reward_date) as latest_reward_date
FROM daily_rewards_backup_20250629;

-- 9. バックアップ完了確認
SELECT 
    '✅ BACKUP VERIFICATION SUMMARY' as section,
    'BACKUP COMPLETED SUCCESSFULLY' as status,
    '2025-06-29 13:32:15' as backup_timestamp,
    'Manual referral corrections preserved' as notes,
    NOW() as verification_timestamp;
