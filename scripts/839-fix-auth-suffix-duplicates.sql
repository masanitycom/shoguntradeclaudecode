-- _authサフィックス問題と重複ユーザーの修正

SELECT '=== _AUTH問題と重複ユーザー修正 ===' as section;

-- 1. 問題のユーザー確認
SELECT '問題のユーザー確認:' as info;
SELECT 
    u.id,
    u.name,
    u.user_id,
    u.email,
    u.created_at,
    CASE 
        -- ハギワラサナエ
        WHEN u.name = 'ハギワラサナエ' AND u.user_id = 'mook0214' AND u.email = 'tokusana371@gmail.com' AND DATE(u.created_at) = '2025-06-24' THEN '正規ユーザー（保持）'
        WHEN u.name = 'ハギワラサナエ' AND u.user_id = 'mook0214_auth' THEN '削除対象（_auth付き）'
        WHEN u.name = 'ハギワラサナエ' AND u.email = 'Tokusana371@gmail.com' THEN '削除対象（大文字メール）'
        -- イシザキイヅミ002
        WHEN u.name = 'イシザキイヅミ002' AND u.user_id = 'Zuurin123002' THEN '正規ユーザー（保持）'
        WHEN u.name = 'イシザキイヅミ002' AND u.user_id = 'Zuurin123_auth' THEN '削除対象（_auth付き）'
        ELSE '要確認'
    END as action
FROM users u
WHERE (u.name = 'ハギワラサナエ' OR u.name = 'イシザキイヅミ002')
ORDER BY u.name, u.created_at;

-- 2. 削除対象の明確化
SELECT '削除対象（_authと重複）:' as deletion_targets;
SELECT 
    u.id,
    u.name,
    u.user_id,
    u.email,
    u.created_at,
    '削除' as action
FROM users u
WHERE 
    -- ハギワラサナエの削除対象
    (u.name = 'ハギワラサナエ' AND u.user_id = 'mook0214_auth')
    OR (u.name = 'ハギワラサナエ' AND u.email = 'Tokusana371@gmail.com' AND DATE(u.created_at) = '2025-06-26')
    -- イシザキイヅミ002の削除対象
    OR (u.name = 'イシザキイヅミ002' AND u.user_id = 'Zuurin123_auth');

-- 3. 正規ユーザーの確認（保護対象）
SELECT '保護する正規ユーザー:' as protected_users;
SELECT 
    u.id,
    u.name,
    u.user_id,
    u.email,
    u.created_at,
    '保持' as action
FROM users u
WHERE 
    -- ハギワラサナエの正規ユーザー
    (u.name = 'ハギワラサナエ' AND u.user_id = 'mook0214' AND u.email = 'tokusana371@gmail.com' AND DATE(u.created_at) = '2025-06-24')
    -- イシザキイヅミ002の正規ユーザー（IDを修正する必要がある）
    OR (u.name = 'イシザキイヅミ002' AND u.user_id = 'Zuurin123002');

-- 4. 削除実行SQL
SELECT '削除実行SQL:' as deletion_sql;
DELETE FROM users 
WHERE 
    -- ハギワラサナエの削除対象
    (name = 'ハギワラサナエ' AND user_id = 'mook0214_auth')
    OR (name = 'ハギワラサナエ' AND email = 'Tokusana371@gmail.com' AND DATE(created_at) = '2025-06-26')
    -- イシザキイヅミ002の削除対象
    OR (name = 'イシザキイヅミ002' AND user_id = 'Zuurin123_auth');

-- 5. 削除後の確認
SELECT '削除後の確認:' as after_deletion;
SELECT 
    u.id,
    u.name,
    u.user_id,
    u.email,
    u.created_at,
    '正規ユーザーのみ残存' as status
FROM users u
WHERE (u.name = 'ハギワラサナエ' OR u.name = 'イシザキイヅミ002')
ORDER BY u.name;

SELECT '=== _AUTH問題修正完了 ===' as status;