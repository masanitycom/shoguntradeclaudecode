-- ==========================================
-- バックアップサマリーレポート
-- 詳細な統計情報と分析結果
-- ==========================================

-- レポート開始
SELECT '📊 BACKUP SUMMARY REPORT' as title, NOW() as generated_at;

-- 1. 基本統計情報
SELECT 
    '=== BASIC STATISTICS ===' as section,
    '' as spacer,
    '' as spacer2;

SELECT 
    table_name,
    record_count,
    backup_date
FROM (
    SELECT 'users_backup_20250629' as table_name, COUNT(*) as record_count, NOW() as backup_date FROM users_backup_20250629
    UNION ALL
    SELECT 'user_nfts_backup_20250629', COUNT(*), NOW() FROM user_nfts_backup_20250629
    UNION ALL
    SELECT 'daily_rewards_backup_20250629', COUNT(*), NOW() FROM daily_rewards_backup_20250629
    UNION ALL
    SELECT 'reward_applications_backup_20250629', COUNT(*), NOW() FROM reward_applications_backup_20250629
    UNION ALL
    SELECT 'nft_purchase_applications_backup_20250629', COUNT(*), NOW() FROM nft_purchase_applications_backup_20250629
    UNION ALL
    SELECT 'user_rank_history_backup_20250629', COUNT(*), NOW() FROM user_rank_history_backup_20250629
    UNION ALL
    SELECT 'tenka_bonus_distributions_backup_20250629', COUNT(*), NOW() FROM tenka_bonus_distributions_backup_20250629
) stats
ORDER BY table_name;

-- 2. ユーザー分析
SELECT 
    '=== USER ANALYSIS ===' as section,
    '' as spacer,
    '' as spacer2;

SELECT 
    'Total Users' as metric,
    COUNT(*) as value,
    'users' as unit
FROM users_backup_20250629

UNION ALL

SELECT 
    'Users with Referrer',
    COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END),
    'users'
FROM users_backup_20250629

UNION ALL

SELECT 
    'Unique Referrers',
    COUNT(DISTINCT referrer_id),
    'users'
FROM users_backup_20250629
WHERE referrer_id IS NOT NULL

UNION ALL

SELECT 
    'Root Users (No Referrer)',
    COUNT(CASE WHEN referrer_id IS NULL THEN 1 END),
    'users'
FROM users_backup_20250629;

-- 3. NFT分析
SELECT 
    '=== NFT ANALYSIS ===' as section,
    '' as spacer,
    '' as spacer2;

SELECT 
    'Total NFT Holdings' as metric,
    COUNT(*) as value,
    'nfts' as unit
FROM user_nfts_backup_20250629

UNION ALL

SELECT 
    'Active NFTs',
    COUNT(CASE WHEN is_active = true THEN 1 END),
    'nfts'
FROM user_nfts_backup_20250629

UNION ALL

SELECT 
    'Users with NFTs',
    COUNT(DISTINCT user_id),
    'users'
FROM user_nfts_backup_20250629

UNION ALL

SELECT 
    'Total Investment Value',
    COALESCE(SUM(purchase_price), 0),
    'USD'
FROM user_nfts_backup_20250629;

-- 4. 報酬分析
SELECT 
    '=== REWARD ANALYSIS ===' as section,
    '' as spacer,
    '' as spacer2;

SELECT 
    'Total Daily Rewards' as metric,
    COUNT(*) as value,
    'records' as unit
FROM daily_rewards_backup_20250629

UNION ALL

SELECT 
    'Total Reward Amount',
    COALESCE(SUM(reward_amount), 0),
    'USD'
FROM daily_rewards_backup_20250629

UNION ALL

SELECT 
    'Users with Rewards',
    COUNT(DISTINCT user_id),
    'users'
FROM daily_rewards_backup_20250629

UNION ALL

SELECT 
    'Average Daily Reward',
    COALESCE(AVG(reward_amount), 0),
    'USD'
FROM daily_rewards_backup_20250629;

-- 5. 紹介ネットワーク分析
SELECT 
    '=== REFERRAL NETWORK ANALYSIS ===' as section,
    '' as spacer,
    '' as spacer2;

WITH referral_stats AS (
    SELECT 
        referrer_id,
        COUNT(*) as direct_referrals
    FROM users_backup_20250629
    WHERE referrer_id IS NOT NULL
    GROUP BY referrer_id
)
SELECT 
    'Top Referrers (>5 referrals)' as metric,
    COUNT(*) as value,
    'users' as unit
FROM referral_stats
WHERE direct_referrals > 5

UNION ALL

SELECT 
    'Max Referrals by Single User',
    MAX(direct_referrals),
    'referrals'
FROM referral_stats

UNION ALL

SELECT 
    'Average Referrals per Referrer',
    COALESCE(AVG(direct_referrals), 0),
    'referrals'
FROM referral_stats;

-- 6. データ品質チェック
SELECT 
    '=== DATA QUALITY CHECK ===' as section,
    '' as spacer,
    '' as spacer2;

SELECT 
    'Broken Referral Links' as check_type,
    COUNT(*) as issues_found,
    CASE WHEN COUNT(*) = 0 THEN '✅ GOOD' ELSE '⚠️ NEEDS ATTENTION' END as status
FROM users_backup_20250629
WHERE referrer_id IS NOT NULL 
AND referrer_id NOT IN (SELECT id FROM users_backup_20250629)

UNION ALL

SELECT 
    'Users without Email',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '✅ GOOD' ELSE '⚠️ NEEDS ATTENTION' END
FROM users_backup_20250629
WHERE email IS NULL OR email = ''

UNION ALL

SELECT 
    'Duplicate Emails',
    COUNT(*) - COUNT(DISTINCT email),
    CASE WHEN COUNT(*) = COUNT(DISTINCT email) THEN '✅ GOOD' ELSE '⚠️ NEEDS ATTENTION' END
FROM users_backup_20250629
WHERE email IS NOT NULL AND email != '';

-- レポート完了
SELECT '✅ BACKUP SUMMARY REPORT COMPLETED' as status, NOW() as completed_at;
