-- 徹底的な構造調査

SELECT '=== COMPREHENSIVE STRUCTURE INVESTIGATION ===' as section;

-- 1. 現在存在するusersレコードの完全確認
SELECT '1. Current users records:' as step;
SELECT 
    id, name, email, user_id, phone, referrer_id, created_at, updated_at
FROM users 
ORDER BY created_at;

-- 2. 既存のバックアップテーブル確認
SELECT '2. Existing backup tables:' as step;
SELECT tablename 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename LIKE '%backup%' 
ORDER BY tablename;

-- 3. user_rank_historyの現在の状況
SELECT '3. user_rank_history current state:' as step;
SELECT user_id, rank_id, achieved_at, created_at
FROM user_rank_history 
ORDER BY created_at;

-- 4. user_nftsの現在の所有状況
SELECT '4. Current NFT ownership:' as step;
SELECT 
    un.user_id,
    u.name as owner_name,
    u.email as owner_email,
    n.name as nft_name,
    un.current_investment,
    un.is_active
FROM user_nfts un
LEFT JOIN users u ON un.user_id = u.id
LEFT JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true
ORDER BY un.user_id;

-- 5. auth.usersとの同期状況
SELECT '5. Auth synchronization status:' as step;
SELECT 
    au.email,
    au.id as auth_id,
    pu.id as public_id,
    pu.name as public_name,
    CASE 
        WHEN au.id = pu.id THEN 'SYNCED'
        WHEN pu.id IS NULL THEN 'AUTH_ONLY'
        WHEN au.id IS NULL THEN 'PUBLIC_ONLY'
        ELSE 'ID_MISMATCH'
    END as sync_status
FROM auth.users au
FULL OUTER JOIN users pu ON au.email = pu.email
WHERE au.email IN ('kappystone.516@gmail.com', 'phu55papa@gmail.com')
   OR pu.email IN ('kappystone.516@gmail.com', 'phu55papa@gmail.com')
ORDER BY au.email, pu.email;

-- 6. 外部キー制約の詳細確認
SELECT '6. Foreign key constraints on users table:' as step;
SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND (ccu.table_name = 'users' OR tc.table_name = 'users')
ORDER BY tc.table_name, tc.constraint_name;

-- 7. 問題のあるレコードの特定
SELECT '7. Problematic records identification:' as step;
SELECT 
    'Records that need fixing' as issue,
    COUNT(*) as count
FROM users 
WHERE email LIKE '%temp%' OR name LIKE '%temp%' OR user_id LIKE '%TEMP%';

-- 8. 修復に必要な具体的アクション
SELECT '8. Required repair actions:' as step;
SELECT 
    'Action needed: Clean existing temp data and create proper sync' as recommendation;