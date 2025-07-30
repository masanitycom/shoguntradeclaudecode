-- 現在の状況を詳細確認

SELECT '=== CURRENT STATE INVESTIGATION ===' as section;

-- kappystone関連の全レコード確認
SELECT 'All kappystone related records:' as check_type;
SELECT 
    id, name, email, user_id, created_at
FROM users 
WHERE email LIKE '%kappystone%' 
   OR name LIKE '%イシジマ%' 
   OR user_id LIKE '%PHULIKE%'
   OR id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
ORDER BY created_at;

-- auth.usersとの同期状況
SELECT 'Auth sync status:' as auth_sync;
SELECT 
    au.email,
    au.id as auth_id,
    pu.id as public_id,
    pu.name,
    pu.user_id,
    CASE WHEN au.id = pu.id THEN 'SYNCED ✓' ELSE 'ERROR ✗' END as sync_status
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE au.email = 'kappystone.516@gmail.com';

-- NFTの現在の所有者
SELECT 'NFT ownership:' as nft_owner;
SELECT 
    un.user_id,
    u.name as owner_name,
    u.email as owner_email,
    un.current_investment
FROM user_nfts un
LEFT JOIN users u ON un.user_id = u.id
WHERE un.current_investment::numeric = 4000
  AND un.is_active = true;

-- 一時レコードの存在確認
SELECT 'Temporary records:' as temp_records;
SELECT 
    id, name, email, user_id
FROM users 
WHERE email LIKE '%temp%' 
   OR user_id LIKE '%TEMP%' 
   OR name LIKE '%temp%'
   OR id = '00000000-0000-0000-0000-000000000001';