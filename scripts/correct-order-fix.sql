-- 正しい順序での修復: NFTデータ → usersテーブルの順

BEGIN;

-- Step 1: サトウチヨコ002のNFTデータを先に新IDに更新
UPDATE user_nfts 
SET user_id = 'f0408d59-9290-4491-92e3-f9d11c50dd15'
WHERE user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

-- Step 2: サトウチヨコ002の関連データも新IDに更新
UPDATE daily_rewards 
SET user_id = 'f0408d59-9290-4491-92e3-f9d11c50dd15' 
WHERE user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

UPDATE nft_purchase_applications 
SET user_id = 'f0408d59-9290-4491-92e3-f9d11c50dd15' 
WHERE user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

UPDATE reward_applications 
SET user_id = 'f0408d59-9290-4491-92e3-f9d11c50dd15' 
WHERE user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

-- Step 3: 紹介関係の更新
UPDATE users 
SET referrer_id = 'f0408d59-9290-4491-92e3-f9d11c50dd15' 
WHERE referrer_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

-- Step 4: サトウチヨコ002用の新しいusersレコード作成
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    'f0408d59-9290-4491-92e3-f9d11c50dd15',
    'サトウチヨコ002',
    'phu55papa@gmail.com',
    'NYANKO002',  -- 一意にするため変更
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

-- Step 5: 古いサトウチヨコ002レコード削除（外部キー参照がなくなったので安全）
DELETE FROM users WHERE id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

COMMIT;

-- 中間確認
SELECT 'Phase 1 completed: Sato data moved successfully' as status;

-- Phase 2: イシジマカツヒロの処理
BEGIN;

-- Step 6: イシジマカツヒロのNFTデータを正しいIDに先に更新  
UPDATE user_nfts 
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- Step 7: イシジマカツヒロの関連データも正しいIDに更新
UPDATE daily_rewards 
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' 
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

UPDATE nft_purchase_applications 
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' 
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

UPDATE reward_applications 
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' 
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- Step 8: 紹介関係の更新
UPDATE users 
SET referrer_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' 
WHERE referrer_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- Step 9: イシジマカツヒロ用の正しいusersレコード作成
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

-- Step 10: 古いイシジマカツヒロレコード削除
DELETE FROM users WHERE id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

COMMIT;

-- 最終検証
SELECT 'COMPLETE SUCCESS!' as final_status;

-- kappystone認証確認
SELECT 
    '=== AUTHENTICATION VERIFICATION ===' as section,
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

-- 両ユーザーの最終状態
SELECT '=== BOTH USERS FINAL STATE ===' as final_users;
SELECT 
    id, name, email, user_id,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = users.id) as nft_count,
    (SELECT SUM(current_investment::numeric) FROM user_nfts WHERE user_id = users.id) as investment
FROM users 
WHERE id IN ('3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c', 'f0408d59-9290-4491-92e3-f9d11c50dd15')
ORDER BY email;