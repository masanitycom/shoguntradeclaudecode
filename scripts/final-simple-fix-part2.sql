-- Part 2: イシジマカツヒロを正しいauth IDに配置

BEGIN;

-- 1. イシジマカツヒロ用の正しいレコード作成
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
    'f2681d3b-d7bb-4397-8117-be543177b840',
    NULL,
    'その他',
    false,
    'PHULIKE',
    'https://shogun-trade.vercel.app/register?ref=PHULIKE',
    '2025-06-29 10:57:38.594245+00',
    NOW()
);

-- 2. イシジマカツヒロのNFTデータを正しいIDに移動
UPDATE user_nfts 
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- 3. 関連データも移動
UPDATE daily_rewards SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';
UPDATE nft_purchase_applications SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';  
UPDATE reward_applications SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- 4. 紹介関係の更新
UPDATE users SET referrer_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE referrer_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- 5. 古いイシジマカツヒロレコード削除
DELETE FROM users WHERE id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

COMMIT;

-- 最終検証
SELECT 'MIGRATION COMPLETED!' as status;

-- kappystone認証確認
SELECT 
    '=== KAPPYSTONE AUTH CHECK ===' as section,
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
SELECT '=== FINAL USER STATES ===' as section;
SELECT 
    name, email, user_id,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = users.id) as nft_count,
    (SELECT SUM(current_investment::numeric) FROM user_nfts WHERE user_id = users.id) as investment
FROM users 
WHERE email IN ('kappystone.516@gmail.com', 'phu55papa@gmail.com')
OR id IN ('3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c', 'f0408d59-9290-4491-92e3-f9d11c50dd15')
ORDER BY email;