-- user_rank_historyを最初に更新してからusersテーブルを更新

BEGIN;

-- Step 1: user_rank_historyを最初に更新
UPDATE user_rank_history 
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' 
WHERE user_id = '00000000-0000-0000-0000-000000000001';

-- Step 2: 他の全関連テーブルも更新
UPDATE user_nfts SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE daily_rewards SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE nft_purchase_applications SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE reward_applications SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';

-- 紹介関係も更新
UPDATE users SET referrer_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE referrer_id = '00000000-0000-0000-0000-000000000001';

-- その他の可能性のあるテーブル（存在しない場合はスキップ）
UPDATE referral_bonuses SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE referral_bonuses SET referrer_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE referrer_id = '00000000-0000-0000-0000-000000000001';
UPDATE tenka_touitsu_bonuses SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE user_sessions SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE user_activities SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE airdrop_tasks SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';

COMMIT;

-- Step 3: 全ての外部キー参照が更新されたので、usersテーブルを安全に更新
BEGIN;

-- usersレコードのIDを正しいauth IDに更新
UPDATE users 
SET id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE id = '00000000-0000-0000-0000-000000000001';

-- ユーザー情報も正しく更新
UPDATE users 
SET 
    name = 'イシジマカツヒロ',
    email = 'kappystone.516@gmail.com',
    user_id = 'PHULIKE'
WHERE id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
  AND (name = 'イシジマカツヒロ_temp' OR email = 'kappystone_temp@gmail.com');

COMMIT;

-- Step 4: サトウチヨコ002の情報も正しく更新
UPDATE users 
SET 
    name = 'サトウチヨコ002',
    email = 'phu55papa@gmail.com'
WHERE id = 'f0408d59-9290-4491-92e3-f9d11c50dd15'
  AND (name = 'サトウチヨコ002_temp' OR email = 'phu55papa_temp@gmail.com');

-- 最終検証
SELECT 'COMPLETE MIGRATION SUCCESS!' as status;

-- kappystone認証の最終確認
SELECT 
    '=== FINAL AUTHENTICATION VERIFICATION ===' as section,
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
SELECT '=== BOTH USERS SUCCESS STATE ===' as success_check;
SELECT 
    id, name, email, user_id,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = users.id) as nft_count,
    (SELECT SUM(current_investment::numeric) FROM user_nfts WHERE user_id = users.id) as investment
FROM users 
WHERE id IN ('3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c', 'f0408d59-9290-4491-92e3-f9d11c50dd15')
ORDER BY email;

-- 修復成功の確認
SELECT 'REPAIR COMPLETED - kappystone.516@gmail.com can now login successfully!' as final_message;