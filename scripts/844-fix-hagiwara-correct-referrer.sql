-- ハギワラサナエさんの正しい紹介者（anshin）に修正

SELECT '=== ハギワラサナエ正しい紹介者修正 ===' as section;

-- 1. anshinユーザーを検索
SELECT 'anshinユーザー検索:' as search;
SELECT 
    id,
    name,
    user_id,
    email
FROM users
WHERE user_id = 'anshin' OR name LIKE '%anshin%' OR email LIKE '%anshin%'
ORDER BY created_at;

-- 2. ハギワラサナエの紹介者をanshinに修正
SELECT 'ハギワラサナエの紹介者をanshinに修正中...' as action;
UPDATE users 
SET referrer_id = (
    SELECT id 
    FROM users 
    WHERE user_id = 'anshin' 
    LIMIT 1
)
WHERE name = 'ハギワラサナエ'
  AND user_id = 'mook0214';

-- 3. 修正後の確認
SELECT '修正後の確認:' as verification;
SELECT 
    u.name,
    u.user_id,
    u.referrer_id,
    r.name as referrer_name,
    r.user_id as referrer_user_id
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.name = 'ハギワラサナエ'
  AND u.user_id = 'mook0214';

SELECT '=== 正しい紹介者修正完了 ===' as status;