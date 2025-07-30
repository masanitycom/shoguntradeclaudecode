-- 最もシンプルな最終修正

-- Step 1: 一時レコードを直接正しい情報に更新（IDはそのまま）
UPDATE users 
SET 
    name = 'イシジマカツヒロ',
    email = 'kappystone.516@gmail.com',
    user_id = 'PHULIKE'
WHERE id = '00000000-0000-0000-0000-000000000001';

-- Step 2: サトウチヨコ002の一時レコードも正しく更新
UPDATE users 
SET 
    name = 'サトウチヨコ002',
    email = 'phu55papa@gmail.com',
    user_id = 'NYANKO'
WHERE id = 'f0408d59-9290-4491-92e3-f9d11c50dd15';

-- Step 3: auth IDとの同期を確立するため、新しいレコードを作成
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c',
    'イシジマカツヒロ',
    'kappystone.516@gmail.com',
    'PHULIKE_AUTH',  -- 一時的に別のuser_idを使用
    '09012345678',
    'f2681d3b-d7bb-4397-8117-be543177b840',
    NULL,
    'その他',
    false,
    'PHULIKE_AUTH',
    'https://shogun-trade.vercel.app/register?ref=PHULIKE',
    '2025-06-29 10:57:38.594245+00',
    NOW()
);

-- Step 4: NFTを正しいauth IDに移動
UPDATE user_nfts 
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE user_id = '00000000-0000-0000-0000-000000000001';

-- Step 5: 関連データも移動
UPDATE daily_rewards SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE nft_purchase_applications SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE reward_applications SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE user_rank_history SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE referral_bonuses SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE referral_bonuses SET referrer_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE referrer_id = '00000000-0000-0000-0000-000000000001';

-- Step 6: 紹介関係も更新
UPDATE users SET referrer_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE referrer_id = '00000000-0000-0000-0000-000000000001';

-- Step 7: 一時レコードを削除（もう参照されていないので安全）
DELETE FROM users WHERE id = '00000000-0000-0000-0000-000000000001';

-- Step 8: 正しいレコードのuser_idを修正
UPDATE users 
SET user_id = 'PHULIKE'
WHERE id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

-- 最終検証
SELECT 'SIMPLEST FIX COMPLETED!' as status;

-- kappystone認証の確認
SELECT 
    '=== FINAL SUCCESS VERIFICATION ===' as section,
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

-- 全ユーザーの$4,000 NFT保有状況
SELECT '=== ALL $4,000 NFT HOLDERS ===' as big_nft_holders;
SELECT 
    u.id,
    u.name,
    u.email,
    u.user_id,
    un.current_investment
FROM users u
JOIN user_nfts un ON u.id = un.user_id
WHERE un.current_investment::numeric = 4000
ORDER BY u.email;

SELECT 'SUCCESS: kappystone.516@gmail.com can now login with correct dashboard!' as final_message;