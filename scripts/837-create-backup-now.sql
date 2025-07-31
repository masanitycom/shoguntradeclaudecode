-- 緊急バックアップ作成（復元前に必須）

SELECT '=== 緊急バックアップ作成 ===' as section;

-- 1. まず現在のNFTデータを確認（消失前のデータがあるか）
SELECT '現在のuser_nftsデータ確認:' as info;
SELECT COUNT(*) as total_nft_records FROM user_nfts;

-- 2. バックアップテーブル作成
SELECT 'バックアップテーブル作成中...' as action;

-- user_nftsのバックアップ
CREATE TABLE IF NOT EXISTS user_nfts_backup_before_restore AS 
SELECT * FROM user_nfts;

-- usersのバックアップ
CREATE TABLE IF NOT EXISTS users_backup_before_restore AS 
SELECT * FROM users;

-- daily_rewardsのバックアップ
CREATE TABLE IF NOT EXISTS daily_rewards_backup_before_restore AS 
SELECT * FROM daily_rewards;

-- 3. バックアップ確認
SELECT 'バックアップ結果:' as result;
SELECT 
    'user_nfts_backup_before_restore' as table_name,
    COUNT(*) as record_count
FROM user_nfts_backup_before_restore
UNION ALL
SELECT 
    'users_backup_before_restore' as table_name,
    COUNT(*) as record_count
FROM users_backup_before_restore
UNION ALL
SELECT 
    'daily_rewards_backup_before_restore' as table_name,
    COUNT(*) as record_count
FROM daily_rewards_backup_before_restore;

SELECT '=== バックアップ作成完了 ===' as status;