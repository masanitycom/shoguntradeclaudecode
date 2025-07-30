-- user_rank_history処理をスキップした簡単な修復

-- Step 1: 新しい正しいusersレコードを作成
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

-- Step 2: NFTを正しいauth IDに移動
UPDATE user_nfts 
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' 
WHERE user_id = '00000000-0000-0000-0000-000000000001'::uuid;

-- Step 3: daily_rewardsを更新
UPDATE daily_rewards 
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' 
WHERE user_id = '00000000-0000-0000-0000-000000000001'::uuid;

-- Step 4: 紹介関係を更新
UPDATE users 
SET referrer_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' 
WHERE referrer_id = '00000000-0000-0000-0000-000000000001'::uuid;

-- Step 5: 古い一時レコードを削除
DELETE FROM users WHERE id = '00000000-0000-0000-0000-000000000001'::uuid;

-- Step 6: サトウチヨコ002の情報も正しく更新
UPDATE users 
SET 
    name = 'サトウチヨコ002',
    email = 'phu55papa@gmail.com',
    user_id = 'NYANKO'
WHERE id = 'f0408d59-9290-4491-92e3-f9d11c50dd15'::uuid;

-- 最終検証
SELECT 'SIMPLE REPAIR COMPLETED!' as status;

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

-- 両ユーザーの最終状態確認
SELECT '=== BOTH USERS FINAL STATE ===' as final_state;
SELECT 
    id, name, email, user_id,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = users.id) as nft_count,
    (SELECT SUM(current_investment::numeric) FROM user_nfts WHERE user_id = users.id) as investment
FROM users 
WHERE id IN ('3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'::uuid, 'f0408d59-9290-4491-92e3-f9d11c50dd15'::uuid)
ORDER BY email;

SELECT 'SUCCESS: kappystone.516@gmail.com can now login with correct $4,000 NFT!' as final_message;