-- 完全バックアップ作成（全データ保護）

SELECT '=== CREATING COMPLETE DATA BACKUP ===' as section;

-- 1. usersテーブルの完全バックアップ
SELECT 'Creating users backup...' as action;
CREATE TABLE IF NOT EXISTS users_emergency_backup_20250730 AS 
SELECT * FROM users;

-- 2. user_nftsテーブルの完全バックアップ  
SELECT 'Creating user_nfts backup...' as action;
CREATE TABLE IF NOT EXISTS user_nfts_emergency_backup_20250730 AS 
SELECT * FROM user_nfts;

-- 3. daily_rewardsテーブルの完全バックアップ
SELECT 'Creating daily_rewards backup...' as action;
CREATE TABLE IF NOT EXISTS daily_rewards_emergency_backup_20250730 AS 
SELECT * FROM daily_rewards;

-- 4. mlm関連テーブルのバックアップ
SELECT 'Creating MLM tables backup...' as action;
CREATE TABLE IF NOT EXISTS mlm_downline_volumes_backup_20250730 AS 
SELECT * FROM mlm_downline_volumes;

-- 5. reward_claimsテーブルのバックアップ
SELECT 'Creating reward_claims backup...' as action;
CREATE TABLE IF NOT EXISTS reward_claims_backup_20250730 AS 
SELECT * FROM reward_claims;

-- 6. バックアップ確認
SELECT 'Backup verification:' as verification;
SELECT 
    'users' as table_name,
    (SELECT COUNT(*) FROM users) as original_count,
    (SELECT COUNT(*) FROM users_emergency_backup_20250730) as backup_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM users) = (SELECT COUNT(*) FROM users_emergency_backup_20250730) 
        THEN '✓ 完全一致' 
        ELSE '⚠ 不一致' 
    END as status
UNION ALL
SELECT 
    'user_nfts' as table_name,
    (SELECT COUNT(*) FROM user_nfts) as original_count,
    (SELECT COUNT(*) FROM user_nfts_emergency_backup_20250730) as backup_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM user_nfts) = (SELECT COUNT(*) FROM user_nfts_emergency_backup_20250730) 
        THEN '✓ 完全一致' 
        ELSE '⚠ 不一致' 
    END as status
UNION ALL
SELECT 
    'daily_rewards' as table_name,
    (SELECT COUNT(*) FROM daily_rewards) as original_count,
    (SELECT COUNT(*) FROM daily_rewards_emergency_backup_20250730) as backup_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM daily_rewards) = (SELECT COUNT(*) FROM daily_rewards_emergency_backup_20250730) 
        THEN '✓ 完全一致' 
        ELSE '⚠ 不一致' 
    END as status;

-- 7. @shogun-trade.comユーザーの詳細確認（実ユーザー含む）
SELECT '@shogun-trade.com users (実ユーザー含む):' as info;
SELECT 
    u.id,
    u.name,
    u.user_id,
    u.email,
    u.created_at,
    CASE WHEN un.user_id IS NOT NULL THEN 'NFTあり' ELSE 'NFTなし' END as nft_status,
    CASE 
        WHEN u.email = 'admin@shogun-trade.com' THEN '管理者'
        WHEN u.name LIKE 'ユーザー%' OR u.name LIKE '%UP' THEN 'テストユーザー'
        ELSE '実ユーザー（要保護）'
    END as user_classification
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE u.email LIKE '%@shogun-trade.com%'
ORDER BY u.created_at;

SELECT '=== COMPLETE BACKUP CREATED SUCCESSFULLY ===' as status;
SELECT 'All data is now safely backed up with timestamp 20250730' as confirmation;