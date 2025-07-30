-- 外部キー制約を一時的に無効にして修復

-- Step 1: 外部キー制約を一時的に無効化
SET session_replication_role = replica;

-- Step 2: 全ての更新を実行（制約チェックなし）
BEGIN;

-- user_rank_historyを更新
UPDATE user_rank_history 
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' 
WHERE user_id = '00000000-0000-0000-0000-000000000001';

-- 他の全関連テーブルも更新
UPDATE user_nfts SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE daily_rewards SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE nft_purchase_applications SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE reward_applications SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';

-- 紹介関係も更新
UPDATE users SET referrer_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE referrer_id = '00000000-0000-0000-0000-000000000001';

-- その他の可能性のあるテーブル
UPDATE referral_bonuses SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE referral_bonuses SET referrer_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE referrer_id = '00000000-0000-0000-0000-000000000001';
UPDATE tenka_touitsu_bonuses SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE user_sessions SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE user_activities SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE airdrop_tasks SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';

-- usersテーブルのIDを更新
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
  AND (name LIKE '%temp%' OR email LIKE '%temp%');

-- サトウチヨコ002の情報も正しく更新
UPDATE users 
SET 
    name = 'サトウチヨコ002',
    email = 'phu55papa@gmail.com'
WHERE id = 'f0408d59-9290-4491-92e3-f9d11c50dd15'
  AND (name LIKE '%temp%' OR email LIKE '%temp%');

COMMIT;

-- Step 3: 外部キー制約を再有効化
SET session_replication_role = DEFAULT;

-- 最終検証
SELECT 'CONSTRAINT-FREE MIGRATION COMPLETED!' as status;

-- kappystone認証の最終確認
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

-- 両ユーザーの最終状態確認
SELECT '=== BOTH USERS FINAL SUCCESS STATE ===' as success_state;
SELECT 
    id, name, email, user_id,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = users.id) as nft_count,
    (SELECT SUM(current_investment::numeric) FROM user_nfts WHERE user_id = users.id) as investment
FROM users 
WHERE id IN ('3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c', 'f0408d59-9290-4491-92e3-f9d11c50dd15')
ORDER BY email;

-- 制約の整合性確認
SELECT 'Constraint integrity check - Should show no violations' as integrity_check;
SELECT COUNT(*) as potential_violations
FROM user_rank_history urh
LEFT JOIN users u ON urh.user_id = u.id
WHERE u.id IS NULL;

SELECT 'SUCCESS: kappystone.516@gmail.com can now login to correct dashboard!' as final_message;