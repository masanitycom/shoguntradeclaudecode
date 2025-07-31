-- ハギワラサナエさんの紹介者情報修正

SELECT '=== ハギワラサナエ紹介者修正 ===' as section;

-- 1. 現在の状況確認
SELECT '現在の紹介者情報:' as info;
SELECT 
    id,
    name,
    user_id,
    referrer_id,
    my_referral_code,
    referral_link
FROM users
WHERE name = 'ハギワラサナエ'
  AND user_id = 'mook0214';

-- 2. 他の実ユーザーの紹介者パターン確認
SELECT '他の実ユーザーの紹介者例:' as examples;
SELECT 
    name,
    user_id,
    referrer_id,
    created_at
FROM users
WHERE referrer_id IS NOT NULL
  AND name NOT LIKE 'A%UP'
  AND name NOT LIKE 'ユーザー%'
ORDER BY created_at
LIMIT 10;

-- 3. 紹介者情報を設定（適切な紹介者IDを設定してください）
SELECT '紹介者情報修正中...' as action;
-- 注意: 適切な紹介者IDを確認してから実行してください
-- UPDATE users 
-- SET referrer_id = '適切な紹介者のuser_id'
-- WHERE name = 'ハギワラサナエ'
--   AND user_id = 'mook0214';

-- 4. 修正後の確認
SELECT '修正後の確認:' as verification;
SELECT 
    u.name,
    u.user_id,
    u.referrer_id,
    r.name as referrer_name,
    u.my_referral_code,
    u.referral_link
FROM users u
LEFT JOIN users r ON u.referrer_id = r.user_id
WHERE u.name = 'ハギワラサナエ'
  AND u.user_id = 'mook0214';

SELECT '=== 紹介者修正準備完了 ===' as status;