-- 46個の孤立auth.usersを処理

SELECT '=== PROCESSING ORPHANED AUTH.USERS ===' as section;

-- Step 1: 孤立auth.usersの詳細リスト（全46個）
SELECT 'Complete list of orphaned auth.users:' as complete_list;
SELECT 
    au.id as auth_id,
    au.email as auth_email,
    au.created_at as auth_created,
    au.email_confirmed_at,
    CASE 
        WHEN au.email LIKE '%@shogun-trade.com' THEN 'SHOGUN_TRADE'
        WHEN au.email LIKE '%@shogun-trade.co' THEN 'SHOGUN_TRADE_CO'
        ELSE 'OTHER'
    END as email_type
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE pu.id IS NULL
ORDER BY au.email;

-- Step 2: 大文字版との対応関係を確認
SELECT 'Uppercase counterparts check:' as uppercase_check;
SELECT 
    au.email as orphaned_auth_email,
    au.id as orphaned_auth_id,
    pu.email as existing_public_email,
    pu.id as existing_public_id,
    pu.name as existing_name,
    pu.user_id as existing_user_id
FROM auth.users au
LEFT JOIN users pu ON UPPER(au.email) = UPPER(pu.email) AND au.id != pu.id
LEFT JOIN users pu2 ON au.id = pu2.id
WHERE pu2.id IS NULL  -- 孤立auth.users
  AND pu.id IS NOT NULL  -- 対応する大文字版が存在
ORDER BY au.email;

-- Step 3: 完全に独立したauth.users（対応するusersレコードが全く存在しない）
SELECT 'Completely independent auth.users:' as independent_auth;
SELECT 
    au.email as independent_email,
    au.id as independent_auth_id,
    au.created_at
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
LEFT JOIN users pu2 ON UPPER(au.email) = UPPER(pu2.email)
WHERE pu.id IS NULL  -- 孤立auth.users
  AND pu2.id IS NULL  -- 大文字版も存在しない
ORDER BY au.email;