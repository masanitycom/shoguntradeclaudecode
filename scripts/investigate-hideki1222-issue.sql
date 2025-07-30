-- hideki1222のログイン問題を詳細調査

SELECT '=== HIDEKI1222 LOGIN ISSUE INVESTIGATION ===' as section;

-- 1. hideki1222関連の全アカウント確認
SELECT 'All hideki1222 related accounts:' as hideki_accounts;
SELECT 
    au.email as auth_email,
    au.id as auth_id,
    au.created_at as auth_created,
    pu.id as public_id,
    pu.name as public_name,
    pu.email as public_email,
    pu.user_id as public_user_id,
    CASE 
        WHEN au.id IS NULL THEN 'NO_AUTH'
        WHEN pu.id IS NULL THEN 'NO_PUBLIC'
        WHEN au.id = pu.id THEN 'SYNCED'
        ELSE 'ID_MISMATCH'
    END as sync_status
FROM auth.users au
FULL OUTER JOIN users pu ON au.email = pu.email
WHERE au.email LIKE '%monchuck%' 
   OR pu.email LIKE '%monchuck%' 
   OR pu.user_id LIKE '%hideki%'
   OR au.email LIKE '%hideki%'
   OR pu.name LIKE '%ヒデキ%'
   OR pu.name LIKE '%タカモト%';

-- 2. monchuck0320@gmail.comの詳細状況
SELECT 'monchuck0320@gmail.com detailed status:' as monchuck_detail;
SELECT 
    au.id as auth_id,
    au.email as auth_email,
    au.email_confirmed_at,
    au.created_at as auth_created,
    pu.id as public_id,
    pu.name as public_name,
    pu.user_id as public_user_id,
    pu.created_at as public_created
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE au.email = 'monchuck0320@gmail.com';

-- 3. NFTデータの確認
SELECT 'hideki1222 NFT data:' as hideki_nft;
SELECT 
    un.user_id,
    u.name as owner_name,
    u.email as owner_email,
    u.user_id as public_user_id,
    un.current_investment,
    un.is_active,
    un.created_at
FROM user_nfts un
LEFT JOIN users u ON un.user_id = u.id
WHERE u.email = 'monchuck0320@gmail.com' 
   OR u.user_id LIKE '%hideki%'
   OR un.user_id = '022ecffe-abdb-44fd-b5b6-430c150d8aab';

-- 4. 46個の孤立auth.usersの詳細リスト
SELECT 'Orphaned auth.users detailed list:' as orphaned_list;
SELECT 
    au.id as auth_id,
    au.email as auth_email,
    au.created_at as auth_created,
    au.email_confirmed_at,
    CASE 
        WHEN au.email_confirmed_at IS NOT NULL THEN 'CONFIRMED'
        ELSE 'UNCONFIRMED'
    END as email_status
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE pu.id IS NULL
ORDER BY au.created_at DESC
LIMIT 10;

-- 5. 孤立auth.usersの統計
SELECT 'Orphaned auth.users statistics:' as orphaned_stats;
SELECT 
    COUNT(*) as total_orphaned,
    COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as confirmed_emails,
    COUNT(CASE WHEN email_confirmed_at IS NULL THEN 1 END) as unconfirmed_emails
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE pu.id IS NULL;