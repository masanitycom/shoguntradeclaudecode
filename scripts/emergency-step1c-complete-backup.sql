-- 完全バックアップの作成（既存のものがあっても上書き）
DROP TABLE IF EXISTS auth_users_backup_emergency;
DROP TABLE IF EXISTS users_backup_emergency;
DROP TABLE IF EXISTS user_nfts_backup_emergency;
DROP TABLE IF EXISTS nft_purchase_applications_backup_emergency;
DROP TABLE IF EXISTS reward_applications_backup_emergency;

-- 新しいバックアップ作成
CREATE TABLE auth_users_backup_emergency AS 
SELECT * FROM auth.users;

CREATE TABLE users_backup_emergency AS 
SELECT * FROM users;

CREATE TABLE user_nfts_backup_emergency AS 
SELECT * FROM user_nfts;

CREATE TABLE nft_purchase_applications_backup_emergency AS 
SELECT * FROM nft_purchase_applications;

CREATE TABLE reward_applications_backup_emergency AS 
SELECT * FROM reward_applications;

-- バックアップ完了確認
SELECT 'FULL BACKUP COMPLETED' as status;
SELECT 
    'auth_users_backup_emergency' as table_name, 
    COUNT(*) as record_count
FROM auth_users_backup_emergency
UNION ALL
SELECT 'users_backup_emergency', COUNT(*)
FROM users_backup_emergency
UNION ALL
SELECT 'user_nfts_backup_emergency', COUNT(*)
FROM user_nfts_backup_emergency
UNION ALL
SELECT 'nft_purchase_applications_backup_emergency', COUNT(*)
FROM nft_purchase_applications_backup_emergency
UNION ALL
SELECT 'reward_applications_backup_emergency', COUNT(*)
FROM reward_applications_backup_emergency;