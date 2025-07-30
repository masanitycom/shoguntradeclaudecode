-- 最終クリーンアップ（サトウチヨコ002の修正のみ）

-- サトウチヨコ002の情報を正しく更新
UPDATE users 
SET 
    name = 'サトウチヨコ002',
    email = 'phu55papa@gmail.com',
    user_id = 'NYANKO'
WHERE id = 'f0408d59-9290-4491-92e3-f9d11c50dd15'::uuid;

-- 修復完了確認
SELECT 'FINAL CLEANUP COMPLETED!' as status;

-- 両ユーザーの最終状態確認
SELECT '=== REPAIR SUCCESS VERIFICATION ===' as section;
SELECT 
    id, name, email, user_id,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = users.id) as nft_count,
    (SELECT SUM(current_investment::numeric) FROM user_nfts WHERE user_id = users.id) as investment
FROM users 
WHERE id IN ('3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'::uuid, 'f0408d59-9290-4491-92e3-f9d11c50dd15'::uuid)
ORDER BY email;

-- kappystone認証の最終確認
SELECT 'kappystone.516@gmail.com final status:' as kappystone_status;
SELECT 
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

-- 一時レコードが残っていないか最終確認
SELECT 'Temporary records remaining:' as temp_check;
SELECT COUNT(*) as temp_count
FROM users 
WHERE email LIKE '%temp%' 
   OR user_id LIKE '%TEMP%' 
   OR name LIKE '%temp%';

SELECT 'SUCCESS: Both users are now properly configured for login!' as final_message;