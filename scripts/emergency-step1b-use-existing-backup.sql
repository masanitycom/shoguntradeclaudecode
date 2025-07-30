-- 既存バックアップを使用して修復を継続
SELECT 'USING EXISTING BACKUP - PROCEEDING WITH REPAIR' as status;

-- 現在の同期状況を再確認
SELECT '=== CURRENT SYNC STATUS ===' as section;
SELECT 
    COALESCE(au.email, pu.email) as email,
    au.id as auth_id,
    pu.id as public_id,
    CASE 
        WHEN au.id IS NULL THEN 'Public Only'
        WHEN pu.id IS NULL THEN 'Auth Only' 
        WHEN au.id = pu.id THEN 'Perfect Match'
        WHEN au.id != pu.id THEN 'ID Mismatch'
        ELSE 'Unknown'
    END as sync_status,
    pu.name as public_name
FROM auth.users au 
FULL OUTER JOIN users pu ON au.email = pu.email
WHERE COALESCE(au.email, pu.email) IN ('kappystone.516@gmail.com', 'kyouko194045@gmail.com')
ORDER BY COALESCE(au.email, pu.email);

-- ID不一致の詳細確認
SELECT '=== ID MISMATCH DETAILS ===' as section;
SELECT 
    au.email,
    au.id as correct_auth_id,
    pu.id as wrong_public_id,
    pu.name,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = pu.id) as nft_count,
    (SELECT SUM(current_investment::numeric) FROM user_nfts WHERE user_id = pu.id) as total_investment
FROM auth.users au
JOIN users pu ON au.email = pu.email AND au.id != pu.id
WHERE au.email IN ('kappystone.516@gmail.com', 'kyouko194045@gmail.com');