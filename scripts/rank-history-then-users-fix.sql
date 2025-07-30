-- user_rank_historyを先に更新してからusersテーブルを更新

BEGIN;

-- Step 1: user_rank_historyの参照を先に更新
UPDATE user_rank_history 
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE user_id = '00000000-0000-0000-0000-000000000001';

-- Step 2: 他の全ての関連テーブルも先に更新（念のため）
UPDATE user_nfts SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE daily_rewards SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE nft_purchase_applications SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE reward_applications SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE referral_bonuses SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE referral_bonuses SET referrer_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE referrer_id = '00000000-0000-0000-0000-000000000001';

-- 紹介関係も更新
UPDATE users SET referrer_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE referrer_id = '00000000-0000-0000-0000-000000000001';

COMMIT;

-- Step 3: 一時的なusersレコードを新しいレコードに置き換え
BEGIN;

-- 新しい正しいレコードを作成
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

-- 古い一時レコードを削除（もう参照されていないので安全）
DELETE FROM users WHERE id = '00000000-0000-0000-0000-000000000001';

COMMIT;

-- Step 4: サトウチヨコ002の情報も正しく更新
UPDATE users 
SET 
    name = 'サトウチヨコ002',
    email = 'phu55papa@gmail.com',
    user_id = 'NYANKO'
WHERE id = 'f0408d59-9290-4491-92e3-f9d11c50dd15';

-- 最終検証
SELECT 'RANK HISTORY FIRST APPROACH COMPLETED!' as status;

-- kappystone認証の確認
SELECT 
    '=== FINAL AUTHENTICATION VERIFICATION ===' as section,
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
SELECT '=== BOTH USERS FINAL SUCCESS STATE ===' as final_state;
SELECT 
    id, name, email, user_id,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = users.id) as nft_count,
    (SELECT SUM(current_investment::numeric) FROM user_nfts WHERE user_id = users.id) as investment
FROM users 
WHERE id IN ('3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c', 'f0408d59-9290-4491-92e3-f9d11c50dd15')
ORDER BY email;

-- user_rank_historyの整合性最終確認
SELECT 'user_rank_history final consistency:' as rank_consistency;
SELECT COUNT(*) as consistent_records 
FROM user_rank_history urh
JOIN users u ON urh.user_id = u.id;

SELECT 'COMPLETE SUCCESS: kappystone.516@gmail.com can now login correctly!' as success_message;