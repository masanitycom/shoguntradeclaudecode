-- ==========================================
-- バックアップからの復元スクリプト
-- 緊急時用の完全復旧機能
-- ==========================================

-- 復元開始メッセージ
SELECT '⚠️ STARTING RESTORE FROM BACKUP - THIS WILL OVERWRITE CURRENT DATA' as warning, NOW() as start_time;

-- 現在のテーブルをバックアップ（復元前の安全措置）
DROP TABLE IF EXISTS users_pre_restore_backup CASCADE;
CREATE TABLE users_pre_restore_backup AS SELECT * FROM users;

DROP TABLE IF EXISTS user_nfts_pre_restore_backup CASCADE;
CREATE TABLE user_nfts_pre_restore_backup AS SELECT * FROM user_nfts;

DROP TABLE IF EXISTS daily_rewards_pre_restore_backup CASCADE;
CREATE TABLE daily_rewards_pre_restore_backup AS SELECT * FROM daily_rewards;

-- 1. usersテーブルの復元
TRUNCATE TABLE users CASCADE;
INSERT INTO users SELECT * FROM users_backup_20250629;

-- 2. user_nftsテーブルの復元
TRUNCATE TABLE user_nfts CASCADE;
INSERT INTO user_nfts SELECT * FROM user_nfts_backup_20250629;

-- 3. daily_rewardsテーブルの復元
TRUNCATE TABLE daily_rewards CASCADE;
INSERT INTO daily_rewards SELECT * FROM daily_rewards_backup_20250629;

-- 4. reward_applicationsテーブルの復元
TRUNCATE TABLE reward_applications CASCADE;
INSERT INTO reward_applications SELECT * FROM reward_applications_backup_20250629;

-- 5. nft_purchase_applicationsテーブルの復元
TRUNCATE TABLE nft_purchase_applications CASCADE;
INSERT INTO nft_purchase_applications SELECT * FROM nft_purchase_applications_backup_20250629;

-- 6. user_rank_historyテーブルの復元
TRUNCATE TABLE user_rank_history CASCADE;
INSERT INTO user_rank_history SELECT * FROM user_rank_history_backup_20250629;

-- 7. tenka_bonus_distributionsテーブルの復元
TRUNCATE TABLE tenka_bonus_distributions CASCADE;
INSERT INTO tenka_bonus_distributions SELECT * FROM tenka_bonus_distributions_backup_20250629;

-- 復元完了確認
SELECT 
    'users' as table_name,
    COUNT(*) as restored_records,
    COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) as users_with_referrer,
    NOW() as restore_time
FROM users

UNION ALL

SELECT 
    'user_nfts' as table_name,
    COUNT(*) as restored_records,
    COUNT(DISTINCT user_id) as unique_users,
    NOW() as restore_time
FROM user_nfts

UNION ALL

SELECT 
    'daily_rewards' as table_name,
    COUNT(*) as restored_records,
    COUNT(DISTINCT user_id) as unique_users,
    NOW() as restore_time
FROM daily_rewards;

-- 復元完了メッセージ
SELECT '✅ RESTORE COMPLETED SUCCESSFULLY' as status, NOW() as timestamp;
