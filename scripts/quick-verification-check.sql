-- 修復結果の簡潔な確認

SELECT '=== REPAIR VERIFICATION SUMMARY ===' as section;

-- kappystone.516@gmail.com の認証同期状況
SELECT 'kappystone.516@gmail.com sync status:' as check_type;
SELECT 
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
SELECT 'Both users final state:' as users_state;
SELECT 
    id, name, email, user_id,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = users.id) as nft_count,
    (SELECT SUM(current_investment::numeric) FROM user_nfts WHERE user_id = users.id) as investment
FROM users 
WHERE email IN ('kappystone.516@gmail.com', 'phu55papa@gmail.com')
   OR id IN ('3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c', 'f0408d59-9290-4491-92e3-f9d11c50dd15')
ORDER BY email;

-- 一時レコードが残っていないか確認
SELECT 'Temporary records cleanup check:' as cleanup_check;
SELECT COUNT(*) as temp_records_remaining
FROM users 
WHERE email LIKE '%temp%' 
   OR user_id LIKE '%TEMP%' 
   OR name LIKE '%temp%'
   OR id = '00000000-0000-0000-0000-000000000001';

-- 修復が成功したかの最終判定
SELECT 'REPAIR SUCCESS STATUS:' as final_status;
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM auth.users au 
            JOIN users pu ON au.id = pu.id 
            WHERE au.email = 'kappystone.516@gmail.com'
        ) THEN 'SUCCESS ✓ - kappystone.516@gmail.com can now login correctly!'
        ELSE 'FAILED ✗ - Authentication still not synchronized'
    END as repair_result;