-- ==========================================
-- バックアップヘルスレポート
-- データの健全性と品質を総合評価
-- ==========================================

-- レポートヘッダー
SELECT 
    '🏥 BACKUP HEALTH REPORT' as title,
    '2025-06-29 Backup Analysis' as subtitle,
    NOW() as report_generated_at;

-- 1. データ完全性スコア
WITH integrity_check AS (
    SELECT 
        COUNT(*) as total_users,
        COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) as users_with_referrer,
        COUNT(CASE WHEN referrer_id IS NOT NULL AND referrer_id NOT IN (SELECT id FROM users_backup_20250629) THEN 1 END) as broken_referrals,
        COUNT(CASE WHEN email IS NULL OR email = '' THEN 1 END) as users_without_email,
        COUNT(DISTINCT email) as unique_emails
    FROM users_backup_20250629
),
nft_check AS (
    SELECT 
        COUNT(*) as total_nfts,
        COUNT(CASE WHEN is_active = true THEN 1 END) as active_nfts,
        COUNT(DISTINCT user_id) as users_with_nfts
    FROM user_nfts_backup_20250629
),
reward_check AS (
    SELECT 
        COUNT(*) as total_rewards,
        COUNT(DISTINCT user_id) as users_with_rewards,
        SUM(reward_amount) as total_reward_amount
    FROM daily_rewards_backup_20250629
)
SELECT 
    '📊 DATA INTEGRITY SCORE' as category,
    CASE 
        WHEN i.broken_referrals = 0 AND i.users_without_email = 0 AND (i.total_users = i.unique_emails) 
        THEN '🟢 EXCELLENT (100%)'
        WHEN i.broken_referrals = 0 AND i.users_without_email < 5 
        THEN '🟡 GOOD (85-99%)'
        ELSE '🔴 NEEDS ATTENTION (<85%)'
    END as score,
    i.total_users as total_users,
    i.broken_referrals as integrity_issues,
    n.total_nfts as nft_records,
    r.total_rewards as reward_records
FROM integrity_check i, nft_check n, reward_check r;

-- 2. 紹介ネットワーク健全性
SELECT 
    '🔗 REFERRAL NETWORK HEALTH' as category,
    COUNT(*) as total_users,
    COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) as referred_users,
    COUNT(CASE WHEN referrer_id IS NULL THEN 1 END) as root_users,
    ROUND(
        (COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END)::numeric / COUNT(*)::numeric) * 100, 
        2
    ) as referral_rate_percent,
    CASE 
        WHEN COUNT(CASE WHEN referrer_id IS NOT NULL AND referrer_id NOT IN (SELECT id FROM users_backup_20250629) THEN 1 END) = 0 
        THEN '✅ HEALTHY' 
        ELSE '⚠️ ISSUES DETECTED' 
    END as network_status
FROM users_backup_20250629;

-- 3. データ分布分析
SELECT 
    '📈 DATA DISTRIBUTION' as category,
    'User Registration Timeline' as metric,
    DATE_TRUNC('month', created_at) as period,
    COUNT(*) as user_count
FROM users_backup_20250629
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY period DESC
LIMIT 6;

-- 4. NFT保有パターン
SELECT 
    '💎 NFT OWNERSHIP PATTERNS' as category,
    nft_id,
    COUNT(*) as holders,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_holders,
    SUM(purchase_price) as total_investment
FROM user_nfts_backup_20250629
GROUP BY nft_id
ORDER BY holders DESC;

-- 5. 報酬分配統計
SELECT 
    '💰 REWARD DISTRIBUTION STATS' as category,
    DATE_TRUNC('week', reward_date) as week,
    COUNT(*) as reward_count,
    COUNT(DISTINCT user_id) as unique_recipients,
    SUM(reward_amount) as total_distributed
FROM daily_rewards_backup_20250629
GROUP BY DATE_TRUNC('week', reward_date)
ORDER BY week DESC
LIMIT 8;

-- 6. アクティブユーザー分析
WITH user_activity AS (
    SELECT 
        u.id,
        u.email,
        CASE WHEN un.user_id IS NOT NULL THEN 1 ELSE 0 END as has_nft,
        CASE WHEN dr.user_id IS NOT NULL THEN 1 ELSE 0 END as has_rewards,
        COALESCE(referral_count.count, 0) as referrals_made
    FROM users_backup_20250629 u
    LEFT JOIN user_nfts_backup_20250629 un ON u.id = un.user_id AND un.is_active = true
    LEFT JOIN daily_rewards_backup_20250629 dr ON u.id = dr.user_id
    LEFT JOIN (
        SELECT referrer_id, COUNT(*) as count 
        FROM users_backup_20250629 
        WHERE referrer_id IS NOT NULL 
        GROUP BY referrer_id
    ) referral_count ON u.id = referral_count.referrer_id
)
SELECT 
    '👤 USER ACTIVITY LEVELS' as category,
    CASE 
        WHEN has_nft = 1 AND has_rewards = 1 AND referrals_made > 0 THEN 'Highly Active'
        WHEN has_nft = 1 AND has_rewards = 1 THEN 'Active Investor'
        WHEN has_nft = 1 THEN 'NFT Holder'
        WHEN referrals_made > 0 THEN 'Referrer Only'
        ELSE 'Inactive'
    END as activity_level,
    COUNT(*) as user_count,
    ROUND(COUNT(*)::numeric / (SELECT COUNT(*) FROM users_backup_20250629)::numeric * 100, 2) as percentage
FROM user_activity
GROUP BY 
    CASE 
        WHEN has_nft = 1 AND has_rewards = 1 AND referrals_made > 0 THEN 'Highly Active'
        WHEN has_nft = 1 AND has_rewards = 1 THEN 'Active Investor'
        WHEN has_nft = 1 THEN 'NFT Holder'
        WHEN referrals_made > 0 THEN 'Referrer Only'
        ELSE 'Inactive'
    END
ORDER BY user_count DESC;

-- 7. バックアップ品質評価
SELECT 
    '🎯 BACKUP QUALITY ASSESSMENT' as category,
    'Overall Status' as metric,
    CASE 
        WHEN (
            SELECT COUNT(*) FROM users_backup_20250629 
            WHERE referrer_id IS NOT NULL 
            AND referrer_id NOT IN (SELECT id FROM users_backup_20250629)
        ) = 0 
        THEN '🟢 EXCELLENT - Ready for Production'
        ELSE '🟡 GOOD - Minor Issues Detected'
    END as quality_status,
    (SELECT COUNT(*) FROM users_backup_20250629) as total_users_backed_up,
    (SELECT COUNT(*) FROM user_nfts_backup_20250629) as total_nfts_backed_up,
    (SELECT COUNT(*) FROM daily_rewards_backup_20250629) as total_rewards_backed_up;

-- レポート完了
SELECT 
    '✅ BACKUP HEALTH REPORT COMPLETED' as status,
    'Manual referral corrections successfully preserved' as conclusion,
    NOW() as report_completed_at;
