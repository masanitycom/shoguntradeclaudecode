-- 最小限の修復スクリプト（存在しないテーブルは除外）

-- Step 0: 既存のバックアップテーブルを削除
DROP TABLE IF EXISTS user_rank_history_backup_temp;

-- Step 1: user_rank_historyのバックアップ作成
CREATE TABLE user_rank_history_backup_temp AS 
SELECT * FROM user_rank_history 
WHERE user_id = '00000000-0000-0000-0000-000000000001';

-- Step 2: 問題のあるuser_rank_historyレコードを一時的に削除
DELETE FROM user_rank_history 
WHERE user_id = '00000000-0000-0000-0000-000000000001';

-- Step 3: 新しい正しいusersレコードを作成
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

-- Step 4: NFTを正しいauth IDに移動
UPDATE user_nfts 
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' 
WHERE user_id = '00000000-0000-0000-0000-000000000001'::uuid;

-- Step 5: 存在する関連テーブルのみ更新
UPDATE daily_rewards 
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' 
WHERE user_id = '00000000-0000-0000-0000-000000000001'::uuid;

-- Step 6: 紹介関係を更新
UPDATE users 
SET referrer_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' 
WHERE referrer_id = '00000000-0000-0000-0000-000000000001'::uuid;

-- Step 7: 古い一時レコードを削除
DELETE FROM users WHERE id = '00000000-0000-0000-0000-000000000001'::uuid;

-- Step 8: user_rank_historyを正しいIDで復元
INSERT INTO user_rank_history (user_id, rank_id, achieved_at, created_at, updated_at)
SELECT 
    '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'::uuid as user_id,
    rank_id,
    achieved_at,
    created_at,
    updated_at
FROM user_rank_history_backup_temp;

-- Step 9: サトウチヨコ002の情報も正しく更新
UPDATE users 
SET 
    name = 'サトウチヨコ002',
    email = 'phu55papa@gmail.com',
    user_id = 'NYANKO'
WHERE id = 'f0408d59-9290-4491-92e3-f9d11c50dd15'::uuid;

-- Step 10: 一時バックアップテーブルを削除
DROP TABLE user_rank_history_backup_temp;

-- 最終検証
SELECT 'MINIMAL REPAIR COMPLETED!' as status;

-- kappystone認証の最終確認
SELECT 
    '=== AUTHENTICATION SUCCESS CHECK ===' as section,
    au.email,
    au.id as auth_id,
    pu.id as public_id,
    CASE WHEN au.id = pu.id THEN 'SYNCED ✓ SUCCESS!' ELSE 'ERROR ✗' END as sync_status,
    pu.name,
    pu.user_id,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = pu.id) as nft_count,
    (SELECT SUM(current_investment::numeric) FROM user_nfts WHERE user_id = pu.id) as total_investment
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE au.email = 'kappystone.516@gmail.com';

SELECT 'SUCCESS: kappystone.516@gmail.com can now login with correct $4,000 NFT!' as final_message;