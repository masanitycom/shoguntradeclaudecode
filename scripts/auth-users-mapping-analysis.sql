-- Supabase AuthとUsersテーブルのマッピング分析

-- 1. auth.usersテーブル（システムテーブル）の確認
-- 注意: このクエリは管理者権限でのみ実行可能
SELECT '=== Auth Users テーブル情報 ===' as section;
SELECT 
    id,
    email,
    created_at,
    updated_at,
    email_confirmed_at,
    last_sign_in_at
FROM auth.users 
WHERE email IN ('kappystone.516@gmail.com', 'phu55papa@gmail.com', 'tokusana371@gmail.com')
   OR id IN ('3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c', '359f44c4-507e-4867-b25d-592f98962145');

-- 2. public.usersテーブルとの照合
SELECT '=== Auth vs Public Users 照合 ===' as section;
SELECT 
    au.id as auth_id,
    au.email as auth_email,
    au.created_at as auth_created,
    pu.id as public_id,
    pu.email as public_email,
    pu.name as public_name,
    pu.created_at as public_created,
    CASE 
        WHEN au.id = pu.id AND au.email = pu.email THEN 'Perfect Match'
        WHEN au.id = pu.id AND au.email != pu.email THEN 'ID Match, Email Mismatch'
        WHEN au.id != pu.id AND au.email = pu.email THEN 'Email Match, ID Mismatch'
        ELSE 'No Match'
    END as match_status
FROM auth.users au
FULL OUTER JOIN users pu ON au.id = pu.id OR au.email = pu.email
WHERE au.email IN ('kappystone.516@gmail.com', 'phu55papa@gmail.com', 'tokusana371@gmail.com')
   OR pu.email IN ('kappystone.516@gmail.com', 'phu55papa@gmail.com', 'tokusana371@gmail.com')
   OR au.id IN ('3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c', '359f44c4-507e-4867-b25d-592f98962145')
   OR pu.id IN ('3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c', '359f44c4-507e-4867-b25d-592f98962145');

-- 3. 孤立したauth.usersレコード（public.usersに対応がない）
SELECT '=== 孤立Auth Users ===' as section;
SELECT 
    au.id,
    au.email,
    au.created_at,
    'No corresponding public.users record' as issue
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE pu.id IS NULL
  AND au.email IN ('kappystone.516@gmail.com', 'phu55papa@gmail.com', 'tokusana371@gmail.com');

-- 4. 孤立したpublic.usersレコード（auth.usersに対応がない）
SELECT '=== 孤立Public Users ===' as section;
SELECT 
    pu.id,
    pu.email,
    pu.name,
    pu.created_at,
    'No corresponding auth.users record' as issue
FROM users pu
LEFT JOIN auth.users au ON pu.id = au.id
WHERE au.id IS NULL
  AND pu.email IN ('kappystone.516@gmail.com', 'phu55papa@gmail.com', 'tokusana371@gmail.com');