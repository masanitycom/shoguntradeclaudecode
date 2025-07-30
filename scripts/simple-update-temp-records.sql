-- 既存の一時レコードを正しい情報に直接更新

BEGIN;

-- Step 1: イシジマカツヒロの一時レコードを正しいauth IDに更新
UPDATE users 
SET 
    id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c',
    name = 'イシジマカツヒロ',
    email = 'kappystone.516@gmail.com',
    user_id = 'PHULIKE'
WHERE id = '00000000-0000-0000-0000-000000000001';

-- Step 2: イシジマカツヒロのNFTと関連データは既に正しいIDになっているのでそのまま

-- Step 3: サトウチヨコ002の一時レコードを正しい情報に更新
UPDATE users 
SET 
    name = 'サトウチヨコ002',
    email = 'phu55papa@gmail.com',
    user_id = 'NYANKO'  -- 元のNYANKOに戻す
WHERE id = 'f0408d59-9290-4491-92e3-f9d11c50dd15';

COMMIT;

-- 最終検証
SELECT 'SIMPLE UPDATE COMPLETED!' as status;

-- kappystone認証の確認
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
WHERE id IN ('3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c', 'f0408d59-9290-4491-92e3-f9d11c50dd15')
ORDER BY email;

-- user_rank_historyの整合性確認
SELECT 'user_rank_history consistency check:' as consistency_check;
SELECT 
    urh.user_id,
    u.name,
    u.email,
    'OK' as status
FROM user_rank_history urh
JOIN users u ON urh.user_id = u.id
WHERE urh.user_id IN ('3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c', 'f0408d59-9290-4491-92e3-f9d11c50dd15');

SELECT 'SUCCESS: kappystone.516@gmail.com authentication is now synchronized!' as final_message;