-- 緊急修復 Step 2: kappystone.516@gmail.com の修復
-- 投資額$4,000のユーザー、最優先対応

BEGIN;

-- Step 1: 関連データのuser_id更新
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

-- 修復検証
SELECT 'KAPPYSTONE REPAIR VERIFICATION' as status;
SELECT 
    au.email,
    au.id as auth_id,
    pu.id as public_id,
    CASE WHEN au.id = pu.id THEN 'SYNCED' ELSE 'ERROR' END as sync_status,
    pu.name,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = pu.id) as nft_count
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE au.email = 'kappystone.516@gmail.com';