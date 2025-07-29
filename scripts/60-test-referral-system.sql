-- 紹介システムの動作テスト

SELECT '=== 紹介システム動作確認 ===' as section;

-- 1. 紹介コードの重複チェック
SELECT 
    my_referral_code,
    COUNT(*) as count
FROM users 
WHERE my_referral_code IS NOT NULL
GROUP BY my_referral_code
HAVING COUNT(*) > 1;

-- 2. 紹介リンクの生成確認
SELECT 
    COUNT(*) as total_users,
    COUNT(my_referral_code) as users_with_code,
    COUNT(referral_link) as users_with_link,
    COUNT(CASE WHEN my_referral_code IS NOT NULL AND referral_link IS NULL THEN 1 END) as missing_links
FROM users 
WHERE is_admin = false;

-- 3. 紹介関係の統計
SELECT 
    '紹介者がいるユーザー' as category,
    COUNT(*) as count
FROM users 
WHERE referrer_id IS NOT NULL
UNION ALL
SELECT 
    '紹介者として機能しているユーザー' as category,
    COUNT(DISTINCT referrer_id) as count
FROM users 
WHERE referrer_id IS NOT NULL;

-- 4. 最新の紹介関係（5件）
SELECT 
    u.name as "被紹介者",
    u.user_id as "被紹介者ID", 
    u.my_referral_code as "被紹介者の紹介コード",
    r.name as "紹介者",
    r.user_id as "紹介者ID",
    r.my_referral_code as "紹介者の紹介コード"
FROM users u
JOIN users r ON u.referrer_id = r.id
ORDER BY u.created_at DESC
LIMIT 5;

SELECT '=== テスト完了 ===' as result;
