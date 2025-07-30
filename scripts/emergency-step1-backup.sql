-- 緊急修復 Step 1: 完全バックアップ
CREATE TABLE auth_users_backup_emergency AS 
SELECT * FROM auth.users;

CREATE TABLE users_backup_emergency AS 
SELECT * FROM users;

CREATE TABLE user_nfts_backup_emergency AS 
SELECT * FROM user_nfts;

CREATE TABLE daily_rewards_backup_emergency AS 
SELECT * FROM daily_rewards;

CREATE TABLE nft_purchase_applications_backup_emergency AS 
SELECT * FROM nft_purchase_applications;

SELECT 'BACKUP COMPLETED' as status;