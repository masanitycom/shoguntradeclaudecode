-- 緊急大規模認証同期修復（本番環境用）
-- Phase 1: 完全バックアップ
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

-- Phase 2: ID Mismatch Cases（最優先）
-- 1. kappystone.516@gmail.com の修復
-- Step 1: 関連データのuser_id更新
BEGIN;

-- NFTデータを正しいauth IDに移動
UPDATE user_nfts 
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- 日利報酬データ更新
UPDATE daily_rewards
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'  
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- NFT購入申請データ更新
UPDATE nft_purchase_applications
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- 報酬申請データ更新
UPDATE reward_applications  
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- 紹介関係の更新（このユーザーを紹介者としている人）
UPDATE users
SET referrer_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE referrer_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- Step 2: 古いpublic.usersレコード削除
DELETE FROM users WHERE id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- Step 3: 正しいIDで新レコード作成
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c',
    'イシジマカツヒロ',
    'kappystone.516@gmail.com',
    'PHULIKE', 
    '09012345678',
    'f2681d3b-d7bb-4397-8117-be543177b840',
    NULL,
    'その他',
    false,
    'PHULIKE',
    'https://shogun-trade.vercel.app/register?ref=PHULIKE',
    '2025-06-29 10:57:38.594245+00',
    NOW()
);

COMMIT;

-- 2. kyouko194045@gmail.com の修復
BEGIN;

-- 関連データの移動
UPDATE user_nfts 
SET user_id = 'cf1d3983-6325-4d60-a15d-4677c08b0859'
WHERE user_id = '0ca07dcd-936b-459a-8cab-ea495029eee2';

UPDATE daily_rewards
SET user_id = 'cf1d3983-6325-4d60-a15d-4677c08b0859'  
WHERE user_id = '0ca07dcd-936b-459a-8cab-ea495029eee2';

UPDATE nft_purchase_applications
SET user_id = 'cf1d3983-6325-4d60-a15d-4677c08b0859'
WHERE user_id = '0ca07dcd-936b-459a-8cab-ea495029eee2';

UPDATE reward_applications  
SET user_id = 'cf1d3983-6325-4d60-a15d-4677c08b0859'
WHERE user_id = '0ca07dcd-936b-459a-8cab-ea495029eee2';

UPDATE users
SET referrer_id = 'cf1d3983-6325-4d60-a15d-4677c08b0859'
WHERE referrer_id = '0ca07dcd-936b-459a-8cab-ea495029eee2';

-- 古いレコード削除
DELETE FROM users WHERE id = '0ca07dcd-936b-459a-8cab-ea495029eee2';

-- 新しいレコード作成（正確な情報が必要）
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    'cf1d3983-6325-4d60-a15d-4677c08b0859',
    'ハセガワキョウコ',
    'kyouko194045@gmail.com',
    'Kyoko001', 
    NULL,
    NULL, -- referrer情報が必要
    NULL,
    'その他',
    false,
    'Kyoko001',
    'https://shogun-trade.vercel.app/register?ref=Kyoko001',
    NOW(),
    NOW()
);

COMMIT;

-- Phase 3: Auth Only Cases（孤立auth.users）
-- tokusana371@gmail.com など84ケースの修復
-- auth.usersにはあるがpublic.usersにないケース

-- Phase 4: 修復後検証
SELECT 'REPAIR VERIFICATION' as status;
SELECT 
    au.email,
    au.id as auth_id,
    pu.id as public_id,
    CASE WHEN au.id = pu.id THEN 'SYNCED' ELSE 'ERROR' END as sync_status,
    pu.name,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = pu.id) as nft_count
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE au.email IN ('kappystone.516@gmail.com', 'kyouko194045@gmail.com', 'tokusana371@gmail.com')
ORDER BY au.email;