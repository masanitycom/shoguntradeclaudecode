-- 2段階移行: サトウチヨコ002を移動後、イシジマカツヒロを正しいIDに配置

BEGIN;

-- Step 1: サトウチヨコ002を新しいIDに移動
-- 新しいUUID生成: f0408d59-9290-4491-92e3-f9d11c50dd15

-- 1-1: サトウチヨコ002のNFTデータを新IDに移動
UPDATE user_nfts 
SET user_id = 'f0408d59-9290-4491-92e3-f9d11c50dd15'
WHERE user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

-- 1-2: サトウチヨコ002の関連データを新IDに移動
UPDATE daily_rewards
SET user_id = 'f0408d59-9290-4491-92e3-f9d11c50dd15'
WHERE user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

UPDATE nft_purchase_applications
SET user_id = 'f0408d59-9290-4491-92e3-f9d11c50dd15'
WHERE user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

UPDATE reward_applications
SET user_id = 'f0408d59-9290-4491-92e3-f9d11c50dd15'
WHERE user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

-- 1-3: サトウチヨコ002を紹介者とする関係を更新
UPDATE users
SET referrer_id = 'f0408d59-9290-4491-92e3-f9d11c50dd15'
WHERE referrer_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

-- 1-4: サトウチヨコ002のusersレコードを新IDで作成
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    'f0408d59-9290-4491-92e3-f9d11c50dd15',
    'サトウチヨコ002',
    'phu55papa@gmail.com',
    'NYANKO',
    '09012345678',
    '8281b9aa-1c9e-4446-bc1f-dbaec25821ec',
    NULL,
    'その他',
    false,
    'NYANKO',
    'https://shogun-trade.vercel.app/register?ref=NYANKO',
    '2025-06-24 07:37:49.967+00',
    NOW()
);

-- 1-5: 古いサトウチヨコ002レコード削除
DELETE FROM users WHERE id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

COMMIT;

-- Step 2: イシジマカツヒロを正しいauth IDに移動
BEGIN;

-- 2-1: イシジマカツヒロのNFTデータを正しいIDに移動
UPDATE user_nfts 
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- 2-2: イシジマカツヒロの関連データを正しいIDに移動
UPDATE daily_rewards
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

UPDATE nft_purchase_applications
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

UPDATE reward_applications
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- 2-3: イシジマカツヒロを紹介者とする関係を更新
UPDATE users
SET referrer_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE referrer_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- 2-4: イシジマカツヒロのusersレコードを正しいIDで作成
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

-- 2-5: 古いイシジマカツヒロレコード削除
DELETE FROM users WHERE id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

COMMIT;

-- 最終検証
SELECT 'TWO-STEP MIGRATION COMPLETED' as status;

-- kappystone.516@gmail.com の同期確認
SELECT 
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

-- 両ユーザーの最終状態確認
SELECT 'Final user states:' as final_check;
SELECT 
    id, name, email, user_id,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = users.id) as nft_count,
    (SELECT SUM(current_investment::numeric) FROM user_nfts WHERE user_id = users.id) as total_investment
FROM users 
WHERE email IN ('kappystone.516@gmail.com', 'phu55papa@gmail.com')
ORDER BY email;