-- ==========================================
-- 完全ユーザーデータバックアップ
-- 手動紹介者修正完了後の安全保存
-- ==========================================

-- バックアップ開始メッセージ
SELECT '🚀 Starting complete user data backup after manual referral corrections' as status, NOW() as start_time;

-- 1. usersテーブルの完全バックアップ
DROP TABLE IF EXISTS users_backup_20250629 CASCADE;
CREATE TABLE users_backup_20250629 AS 
SELECT * FROM users;

-- インデックス作成
CREATE INDEX idx_users_backup_20250629_id ON users_backup_20250629(id);
CREATE INDEX idx_users_backup_20250629_email ON users_backup_20250629(email);
CREATE INDEX idx_users_backup_20250629_referrer_id ON users_backup_20250629(referrer_id);

-- 2. user_nftsテーブルのバックアップ
DROP TABLE IF EXISTS user_nfts_backup_20250629 CASCADE;
CREATE TABLE user_nfts_backup_20250629 AS 
SELECT * FROM user_nfts;

CREATE INDEX idx_user_nfts_backup_20250629_user_id ON user_nfts_backup_20250629(user_id);
CREATE INDEX idx_user_nfts_backup_20250629_nft_id ON user_nfts_backup_20250629(nft_id);

-- 3. daily_rewardsテーブルのバックアップ
DROP TABLE IF EXISTS daily_rewards_backup_20250629 CASCADE;
CREATE TABLE daily_rewards_backup_20250629 AS 
SELECT * FROM daily_rewards;

CREATE INDEX idx_daily_rewards_backup_20250629_user_id ON daily_rewards_backup_20250629(user_id);
CREATE INDEX idx_daily_rewards_backup_20250629_date ON daily_rewards_backup_20250629(reward_date);

-- 4. reward_applicationsテーブルのバックアップ
DROP TABLE IF EXISTS reward_applications_backup_20250629 CASCADE;
CREATE TABLE reward_applications_backup_20250629 AS 
SELECT * FROM reward_applications;

CREATE INDEX idx_reward_applications_backup_20250629_user_id ON reward_applications_backup_20250629(user_id);

-- 5. nft_purchase_applicationsテーブルのバックアップ
DROP TABLE IF EXISTS nft_purchase_applications_backup_20250629 CASCADE;
CREATE TABLE nft_purchase_applications_backup_20250629 AS 
SELECT * FROM nft_purchase_applications;

CREATE INDEX idx_nft_purchase_applications_backup_20250629_user_id ON nft_purchase_applications_backup_20250629(user_id);

-- 6. user_rank_historyテーブルのバックアップ
DROP TABLE IF EXISTS user_rank_history_backup_20250629 CASCADE;
CREATE TABLE user_rank_history_backup_20250629 AS 
SELECT * FROM user_rank_history;

CREATE INDEX idx_user_rank_history_backup_20250629_user_id ON user_rank_history_backup_20250629(user_id);

-- 7. tenka_bonus_distributionsテーブルのバックアップ
DROP TABLE IF EXISTS tenka_bonus_distributions_backup_20250629 CASCADE;
CREATE TABLE tenka_bonus_distributions_backup_20250629 AS 
SELECT * FROM tenka_bonus_distributions;

CREATE INDEX idx_tenka_bonus_distributions_backup_20250629_user_id ON tenka_bonus_distributions_backup_20250629(user_id);

-- バックアップ完了確認
SELECT 
    'users_backup_20250629' as table_name,
    COUNT(*) as record_count,
    COUNT(DISTINCT referrer_id) as unique_referrers,
    COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) as users_with_referrer,
    NOW() as backup_time
FROM users_backup_20250629

UNION ALL

SELECT 
    'user_nfts_backup_20250629' as table_name,
    COUNT(*) as record_count,
    COUNT(DISTINCT user_id) as unique_referrers,
    COUNT(DISTINCT user_id) as users_with_referrer,
    NOW() as backup_time
FROM user_nfts_backup_20250629

UNION ALL

SELECT 
    'daily_rewards_backup_20250629' as table_name,
    COUNT(*) as record_count,
    COUNT(DISTINCT user_id) as unique_referrers,
    SUM(reward_amount) as users_with_referrer,
    NOW() as backup_time
FROM daily_rewards_backup_20250629

UNION ALL

SELECT 
    'reward_applications_backup_20250629' as table_name,
    COUNT(*) as record_count,
    COUNT(DISTINCT user_id) as unique_referrers,
    COUNT(DISTINCT user_id) as users_with_referrer,
    NOW() as backup_time
FROM reward_applications_backup_20250629;

-- 完了メッセージ
SELECT '✅ BACKUP COMPLETED SUCCESSFULLY' as status, NOW() as timestamp;
