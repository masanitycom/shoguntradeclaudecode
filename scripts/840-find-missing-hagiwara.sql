-- ハギワラサナエさんの正規ユーザー緊急捜索

SELECT '=== ハギワラサナエ正規ユーザー緊急捜索 ===' as section;

-- 1. ハギワラサナエで検索（あらゆるパターン）
SELECT 'ハギワラサナエ全パターン:' as info;
SELECT 
    id,
    name,
    user_id,
    email,
    created_at,
    phone
FROM users
WHERE name LIKE '%ハギワラ%' OR name LIKE '%サナエ%'
ORDER BY created_at;

-- 2. mook0214で検索
SELECT 'mook0214で検索:' as info;
SELECT 
    id,
    name,
    user_id,
    email,
    created_at
FROM users
WHERE user_id LIKE '%mook%'
ORDER BY created_at;

-- 3. tokusana371@gmail.comで検索
SELECT 'tokusana371@gmail.comで検索:' as info;
SELECT 
    id,
    name,
    user_id,
    email,
    created_at
FROM users
WHERE email LIKE '%tokusana%'
ORDER BY created_at;

-- 4. 2025/6/24登録のユーザー確認
SELECT '2025/6/24登録のユーザー:' as info;
SELECT 
    id,
    name,
    user_id,
    email,
    created_at
FROM users
WHERE DATE(created_at) = '2025-06-24'
ORDER BY name;

SELECT '=== 捜索完了 ===' as status;