-- 重複キーエラーの修正: UPDATE方式で既存レコードを更新

BEGIN;

-- Step 1: 既存の混在レコードをkappystone.516@gmail.com用に更新
UPDATE users 
SET 
    name = 'イシジマカツヒロ',
    email = 'kappystone.516@gmail.com',
    user_id = 'PHULIKE',
    phone = '09012345678',
    referrer_id = 'f2681d3b-d7bb-4397-8117-be543177b840',
    usdt_address = NULL,
    wallet_type = 'その他',
    is_admin = false,
    my_referral_code = 'PHULIKE',
    referral_link = 'https://shogun-trade.vercel.app/register?ref=PHULIKE',
    updated_at = NOW()
WHERE id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

-- Step 2: 間違ったIDのレコード削除
DELETE FROM users WHERE id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- Step 3: NFTデータを正しいIDに移動（kappystone → 正しいauth ID）
UPDATE user_nfts 
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- Step 4: 関連データの更新
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

-- Step 5: phu55papa@gmail.com用の新しいレコード作成（新しいUUID使用）
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    'f0408d59-9290-4491-92e3-f9d11c50dd15',  -- 新しいUUID
    'サトウチヨコ002',
    'phu55papa@gmail.com',
    'NYANKO',
    NULL,
    NULL,
    NULL,
    'その他',
    false,
    'NYANKO',
    'https://shogun-trade.vercel.app/register?ref=NYANKO',
    '2025-06-24 07:37:49.967+00',
    NOW()
);

-- 修復結果の検証
SELECT 'REPAIR VERIFICATION' as status;
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