-- usersレコード優先アプローチ: 参照先を先に作成

BEGIN;

-- Step 1: サトウチヨコ002用の新しいusersレコードを先に作成
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    'f0408d59-9290-4491-92e3-f9d11c50dd15',
    'サトウチヨコ002_temp',  -- 一時的に名前を変更して重複回避
    'phu55papa_temp@gmail.com',  -- 一時的にメールを変更
    'NYANKO002',
    '09012345678',
    '8281b9aa-1c9e-4446-bc1f-dbaec25821ec',
    NULL,
    'その他',
    false,
    'NYANKO002',
    'https://shogun-trade.vercel.app/register?ref=NYANKO002',
    '2025-06-24 07:37:49.967+00',
    NOW()
);

-- Step 2: イシジマカツヒロ用の新しいusersレコードも作成
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    '00000000-0000-0000-0000-000000000001',  -- 一時的なID
    'イシジマカツヒロ_temp',
    'kappystone_temp@gmail.com',
    'PHULIKE_TEMP',
    '09012345678',
    'f2681d3b-d7bb-4397-8117-be543177b840',
    NULL,
    'その他',
    false,
    'PHULIKE_TEMP',
    'https://shogun-trade.vercel.app/register?ref=PHULIKE_TEMP',
    '2025-06-29 10:57:38.594245+00',
    NOW()
);

COMMIT;

-- Step 3: NFTデータの移動
BEGIN;

-- サトウチヨコ002のNFTデータを新IDに移動
UPDATE user_nfts 
SET user_id = 'f0408d59-9290-4491-92e3-f9d11c50dd15'
WHERE user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

-- イシジマカツヒロのNFTデータを一時IDに移動
UPDATE user_nfts 
SET user_id = '00000000-0000-0000-0000-000000000001'
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- 関連データも移動
UPDATE daily_rewards SET user_id = 'f0408d59-9290-4491-92e3-f9d11c50dd15' WHERE user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';
UPDATE daily_rewards SET user_id = '00000000-0000-0000-0000-000000000001' WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

UPDATE nft_purchase_applications SET user_id = 'f0408d59-9290-4491-92e3-f9d11c50dd15' WHERE user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';
UPDATE nft_purchase_applications SET user_id = '00000000-0000-0000-0000-000000000001' WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

UPDATE reward_applications SET user_id = 'f0408d59-9290-4491-92e3-f9d11c50dd15' WHERE user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';
UPDATE reward_applications SET user_id = '00000000-0000-0000-0000-000000000001' WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- 紹介関係の更新
UPDATE users SET referrer_id = 'f0408d59-9290-4491-92e3-f9d11c50dd15' WHERE referrer_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';
UPDATE users SET referrer_id = '00000000-0000-0000-0000-000000000001' WHERE referrer_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

COMMIT;

-- Step 4: 古いレコードを削除
DELETE FROM users WHERE id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';
DELETE FROM users WHERE id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- Step 5: 最終的な正しいレコードに更新
BEGIN;

-- サトウチヨコ002を正しい情報に更新
UPDATE users 
SET 
    name = 'サトウチヨコ002',
    email = 'phu55papa@gmail.com'
WHERE id = 'f0408d59-9290-4491-92e3-f9d11c50dd15';

-- イシジマカツヒロを正しいIDと情報に更新
UPDATE users 
SET 
    id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c',
    name = 'イシジマカツヒロ',
    email = 'kappystone.516@gmail.com',
    user_id = 'PHULIKE'
WHERE id = '00000000-0000-0000-0000-000000000001';

-- イシジマカツヒロのNFTデータを正しいIDに更新
UPDATE user_nfts SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';

-- 関連データも正しいIDに更新
UPDATE daily_rewards SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE nft_purchase_applications SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE reward_applications SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE users SET referrer_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE referrer_id = '00000000-0000-0000-0000-000000000001';

COMMIT;

-- 最終検証
SELECT 'MIGRATION COMPLETED SUCCESSFULLY!' as status;

-- kappystone認証確認
SELECT 
    '=== FINAL AUTHENTICATION CHECK ===' as section,
    au.email,
    au.id as auth_id,
    pu.id as public_id,
    CASE WHEN au.id = pu.id THEN 'SYNCED ✓' ELSE 'ERROR ✗' END as sync_status,
    pu.name,
    pu.user_id,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = pu.id) as nft_count,
    (SELECT SUM(current_investment::numeric) FROM user_nfts WHERE user_id = pu.id) as total_investment
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE au.email = 'kappystone.516@gmail.com';