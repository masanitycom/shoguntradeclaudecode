-- 最終修復: kappystone.516@gmail.com の正しい同期
-- 新しいUUID: f0408d59-9290-4491-92e3-f9d11c50dd15 を使用

BEGIN;

-- Step 1: kappystone.516@gmail.com用の正しいpublic.usersレコード作成
-- 既存の間違ったIDのレコード削除
DELETE FROM users WHERE id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- 正しいauth IDで新しいレコード作成  
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c',  -- 正しいauth ID
    'イシジマカツヒロ',
    'kappystone.516@gmail.com',
    'PHULIKE', 
    '09012345678',
    'f2681d3b-d7bb-4397-8117-be543177b840',  -- 紹介者ID
    NULL,
    'その他',
    false,
    'PHULIKE',
    'https://shogun-trade.vercel.app/register?ref=PHULIKE',
    '2025-06-29 10:57:38.594245+00',
    NOW()
);

-- Step 2: NFTデータを正しいIDに移動
UPDATE user_nfts 
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- Step 3: 関連データの更新
UPDATE daily_rewards
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'  
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

UPDATE nft_purchase_applications
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

UPDATE reward_applications  
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- 紹介関係の更新
UPDATE users
SET referrer_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE referrer_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

COMMIT;

-- 修復結果の検証
SELECT 'KAPPYSTONE REPAIR COMPLETED' as status;
SELECT 
    au.email,
    au.id as auth_id,
    pu.id as public_id,
    CASE WHEN au.id = pu.id THEN 'SYNCED ✓' ELSE 'ERROR ✗' END as sync_status,
    pu.name,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = pu.id) as nft_count,
    (SELECT SUM(current_investment::numeric) FROM user_nfts WHERE user_id = pu.id) as total_investment
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE au.email = 'kappystone.516@gmail.com';