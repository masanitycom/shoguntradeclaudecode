-- ハギワラサナエさんの紹介者情報修正（型修正版）

SELECT '=== ハギワラサナエ紹介者修正 ===' as section;

-- 1. 共通の紹介者ID確認（他のユーザーが使っている紹介者）
SELECT '共通紹介者ID:' as common_referrer;
SELECT 
    referrer_id,
    COUNT(*) as referred_count
FROM users
WHERE referrer_id IS NOT NULL
  AND name NOT LIKE 'A%UP'
  AND name NOT LIKE 'ユーザー%'
GROUP BY referrer_id
ORDER BY referred_count DESC
LIMIT 5;

-- 2. 最も使われている紹介者の詳細確認
SELECT '最も使われている紹介者:' as top_referrer;
SELECT 
    id,
    name,
    user_id,
    email
FROM users
WHERE id = '673c8ad6-7365-4d9c-903f-acde1cb00d4a';

-- 3. ハギワラサナエさんに同じ紹介者を設定
SELECT 'ハギワラサナエに紹介者設定中...' as action;
UPDATE users 
SET referrer_id = '673c8ad6-7365-4d9c-903f-acde1cb00d4a'
WHERE name = 'ハギワラサナエ'
  AND user_id = 'mook0214';

-- 4. 修正後の確認（型キャストで修正）
SELECT '修正後の確認:' as verification;
SELECT 
    u.name,
    u.user_id,
    u.referrer_id,
    r.name as referrer_name,
    r.user_id as referrer_user_id
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id  -- idで結合（UUIDとUUID）
WHERE u.name = 'ハギワラサナエ'
  AND u.user_id = 'mook0214';

SELECT '=== 紹介者修正完了 ===' as status;