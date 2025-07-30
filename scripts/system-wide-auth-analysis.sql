-- システム全体の認証同期問題の調査

-- 1. 全ユーザーの同期状況を調査
SELECT '=== 全体の同期状況調査 ===' as section;

-- auth.usersとpublic.usersの数を比較
SELECT 
    'Count Comparison' as analysis_type,
    (SELECT COUNT(*) FROM auth.users) as auth_users_count,
    (SELECT COUNT(*) FROM users) as public_users_count,
    (SELECT COUNT(*) FROM auth.users) - (SELECT COUNT(*) FROM users) as difference;

-- 2. メールアドレスでの照合（同期エラーの検出）
SELECT '=== メールアドレス照合による同期エラー検出 ===' as section;
SELECT 
    COALESCE(au.email, pu.email) as email,
    au.id as auth_id,
    pu.id as public_id,
    CASE 
        WHEN au.id IS NULL THEN 'Public Only (孤立public.users)'
        WHEN pu.id IS NULL THEN 'Auth Only (孤立auth.users)' 
        WHEN au.id = pu.id THEN 'Perfect Match'
        WHEN au.id != pu.id THEN 'ID Mismatch (同期エラー)'
        ELSE 'Unknown'
    END as sync_status,
    pu.name as public_name,
    pu.user_id as public_user_id
FROM auth.users au 
FULL OUTER JOIN users pu ON au.email = pu.email
ORDER BY 
    CASE 
        WHEN au.id IS NULL THEN 1
        WHEN pu.id IS NULL THEN 2  
        WHEN au.id != pu.id THEN 3
        ELSE 4
    END,
    COALESCE(au.email, pu.email);

-- 3. hideki1222 の詳細調査
SELECT '=== hideki1222 ユーザーの詳細調査 ===' as section;
SELECT 
    'auth.users search' as search_type,
    id, email, created_at, last_sign_in_at
FROM auth.users 
WHERE email LIKE '%hideki%' OR id IN (
    SELECT id FROM users WHERE user_id = 'hideki1222'
);

SELECT 
    'public.users search' as search_type,
    id, name, email, user_id, created_at
FROM users 
WHERE user_id = 'hideki1222' OR email LIKE '%hideki%';

-- 4. 同期エラーのパターン分析
SELECT '=== 同期エラーパターンの統計 ===' as section;
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

-- 5. 最も影響の大きいID不一致ケースの特定
SELECT '=== 重要な同期エラーケース（NFT保有者） ===' as section;
SELECT 
    au.email,
    au.id as auth_id,
    pu.id as public_id,
    pu.name as public_name,
    pu.user_id as public_user_id,
    COUNT(un.id) as nft_count,
    SUM(un.current_investment::numeric) as total_investment
FROM auth.users au 
JOIN users pu ON au.email = pu.email AND au.id != pu.id
LEFT JOIN user_nfts un ON pu.id = un.user_id AND un.is_active = true
GROUP BY au.email, au.id, pu.id, pu.name, pu.user_id
HAVING COUNT(un.id) > 0
ORDER BY total_investment DESC;