-- 緊急修復 Step 4: 全体検証

-- ID不一致問題の修復確認
SELECT '=== ID MISMATCH REPAIR VERIFICATION ===' as section;
SELECT 
    au.email,
    au.id as auth_id,
    pu.id as public_id,
    CASE WHEN au.id = pu.id THEN 'SYNCED ✓' ELSE 'ERROR ✗' END as sync_status,
    pu.name,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = pu.id) as nft_count,
    (SELECT SUM(current_investment::numeric) FROM user_nfts WHERE user_id = pu.id) as total_investment
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE au.email IN ('kappystone.516@gmail.com', 'kyouko194045@gmail.com')
ORDER BY au.email;

-- 全体同期状況の再確認
SELECT '=== OVERALL SYNC STATUS ===' as section;
SELECT 
    sync_status,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM (
    SELECT 
        CASE 
            WHEN au.id IS NULL THEN 'Public Only'
            WHEN pu.id IS NULL THEN 'Auth Only' 
            WHEN au.id = pu.id THEN 'Perfect Match'
            WHEN au.id != pu.id THEN 'ID Mismatch'
            ELSE 'Unknown'
        END as sync_status
    FROM auth.users au 
    FULL OUTER JOIN users pu ON au.email = pu.email
) sync_analysis
GROUP BY sync_status
ORDER BY count DESC;

-- 残りのID不一致ケース確認
SELECT '=== REMAINING ID MISMATCH CASES ===' as section;
SELECT 
    au.email,
    au.id as auth_id,
    pu.id as public_id,
    pu.name,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = pu.id) as nft_count
FROM auth.users au
JOIN users pu ON au.email = pu.email AND au.id != pu.id;

-- hideki1222問題の確認
SELECT '=== HIDEKI1222 STATUS CHECK ===' as section;
SELECT 
    'auth.users' as table_name,
    id, email, created_at
FROM auth.users 
WHERE email LIKE '%hideki%' OR id IN (
    SELECT id FROM users WHERE user_id = 'hideki1222'
)
UNION ALL
SELECT 
    'public.users' as table_name,
    id, email, created_at
FROM users 
WHERE user_id = 'hideki1222' OR email LIKE '%hideki%';