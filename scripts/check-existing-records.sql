-- 既存レコードの状況確認

SELECT '=== EXISTING RECORDS CHECK ===' as section;

-- tokusana371@gmail.com関連のレコード確認
SELECT 'tokusana371@gmail.com related records:' as tokusana_records;
SELECT 
    id, name, email, user_id, created_at
FROM users 
WHERE email LIKE '%tokusana%' 
   OR id = '359f44c4-507e-4867-b25d-592f98962145'
ORDER BY created_at;

-- a3@shogun-trade.com関連のレコード確認
SELECT 'a3@shogun-trade.com related records:' as a3_records;
SELECT 
    id, name, email, user_id, created_at
FROM users 
WHERE email LIKE '%a3@shogun%' 
   OR id = '9ed30a48-e5cd-483b-8d79-c84fb5248d48'
ORDER BY created_at;

-- auth.usersとの同期状況
SELECT 'Auth sync status for problem users:' as auth_sync;
SELECT 
    au.email as auth_email,
    au.id as auth_id,
    pu.id as public_id,
    pu.name as public_name,
    pu.user_id as public_user_id,
    CASE WHEN au.id = pu.id THEN 'SYNCED ✓' ELSE 'NO_SYNC ✗' END as sync_status
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE au.email IN ('tokusana371@gmail.com', 'a3@shogun-trade.com')
ORDER BY au.email;