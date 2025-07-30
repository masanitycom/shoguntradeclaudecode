-- 問題のあるユーザー3人の詳細調査

SELECT '=== PROBLEM USERS INVESTIGATION ===' as section;

-- 1. hideki1222 (ログインできない)
SELECT 'hideki1222 investigation:' as user1_check;
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
WHERE au.email LIKE '%hideki%' OR pu.email LIKE '%hideki%' OR pu.user_id LIKE '%hideki%';

-- 2. mook0214 (tokusana371@gmail.com)
SELECT 'mook0214 (tokusana371@gmail.com) investigation:' as user2_check;
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
WHERE au.email = 'tokusana371@gmail.com' OR pu.email = 'tokusana371@gmail.com' OR pu.user_id LIKE '%mook%';

-- 3. Zuurin123002 (a3@shogun-trade.com)
SELECT 'Zuurin123002 (a3@shogun-trade.com) investigation:' as user3_check;
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
WHERE au.email = 'a3@shogun-trade.com' OR pu.email = 'a3@shogun-trade.com' OR pu.user_id LIKE '%Zuurin%';

-- 4. これらのユーザーのNFT保有状況も確認
SELECT 'NFT ownership for these users:' as nft_check;
SELECT 
    un.user_id,
    u.name as owner_name,
    u.email as owner_email,
    un.current_investment,
    un.is_active
FROM user_nfts un
LEFT JOIN users u ON un.user_id = u.id
WHERE u.email IN ('tokusana371@gmail.com', 'a3@shogun-trade.com')
   OR u.user_id LIKE '%hideki%'
   OR u.user_id LIKE '%mook%'
   OR u.user_id LIKE '%Zuurin%'
   OR un.user_id IN (
       '359f44c4-507e-4867-b25d-592f98962145',
       '9ed30a48-e5cd-483b-8d79-c84fb5248d48'
   );

-- 5. 孤立したauth.usersの確認（usersレコードがないauth）
SELECT 'Orphaned auth users count:' as orphan_count;
SELECT COUNT(*) as orphaned_auth_users
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE pu.id IS NULL;