-- 大規模認証同期修復計画（本番環境用）

-- === 修復戦略 ===
-- 1. auth.users を基準とする（認証が最重要）
-- 2. public.users のIDをauth.users のIDに合わせる
-- 3. 関連データ（user_nfts, daily_rewards等）のuser_idを更新
-- 4. データの完全性を保持

-- === PHASE 1: 完全バックアップ ===
/*
CREATE TABLE users_backup_before_sync_repair AS SELECT * FROM users;
CREATE TABLE user_nfts_backup_before_sync_repair AS SELECT * FROM user_nfts;  
CREATE TABLE daily_rewards_backup_before_sync_repair AS SELECT * FROM daily_rewards;
CREATE TABLE nft_purchase_applications_backup_before_sync_repair AS SELECT * FROM nft_purchase_applications;
CREATE TABLE reward_applications_backup_before_sync_repair AS SELECT * FROM reward_applications;
*/

-- === PHASE 2: 修復対象の特定 ===
-- メールアドレスが一致するがIDが異なるケースを特定
SELECT 'REPAIR TARGETS - ID Mismatch Cases' as analysis;
SELECT 
    au.email,
    au.id as correct_auth_id,
    pu.id as wrong_public_id, 
    pu.name,
    pu.user_id as display_user_id,
    -- 関連データの数を確認
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = pu.id) as nft_count,
    (SELECT COUNT(*) FROM daily_rewards WHERE user_id = pu.id) as rewards_count
FROM auth.users au
JOIN users pu ON au.email = pu.email AND au.id != pu.id
ORDER BY pu.name;

-- === PHASE 3: 孤立auth.usersの処理計画 ===
-- auth.usersにあるがpublic.usersにないケース
SELECT 'ORPHANED AUTH USERS - Need public.users creation' as analysis;
SELECT 
    au.id as auth_id,
    au.email,
    au.created_at as auth_created,
    au.last_sign_in_at
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE pu.id IS NULL
ORDER BY au.created_at;

-- === PHASE 4: 実際の修復SQL（テンプレート） ===
-- 注意: これは手動で各ケースを確認してから実行する

/*
-- 例: kappystone.516@gmail.com の修復
-- ステップ1: 関連データのuser_id更新
UPDATE user_nfts 
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

UPDATE daily_rewards
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'  
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

UPDATE nft_purchase_applications
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

UPDATE reward_applications  
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- ステップ2: 古いpublic.usersレコード削除
DELETE FROM users WHERE id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- ステップ3: 正しいIDで新しいレコード作成
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
*/

-- === PHASE 5: 修復後の検証 ===
/*
-- 同期状況の再確認
SELECT 
    'POST-REPAIR VERIFICATION' as status,
    au.email,
    au.id as auth_id,
    pu.id as public_id,
    CASE WHEN au.id = pu.id THEN 'SYNCED' ELSE 'ERROR' END as sync_status
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE au.email IN ('kappystone.516@gmail.com', 'tokusana371@gmail.com')
ORDER BY au.email;
*/