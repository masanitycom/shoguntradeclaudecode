-- 新規登録ユーザーの紹介リンク確認
SELECT 
    name,
    user_id,
    referral_link,
    created_at,
    CASE 
        WHEN referral_link IS NOT NULL THEN '✅ リンクあり'
        ELSE '❌ リンクなし'
    END as link_status
FROM users 
WHERE is_admin = false
ORDER BY created_at DESC
LIMIT 10;

-- 統計情報
SELECT 
    '=== 紹介リンク統計 ===' as title,
    COUNT(*) as total_users,
    COUNT(referral_link) as users_with_links,
    ROUND(COUNT(referral_link) * 100.0 / COUNT(*), 2) as percentage_with_links
FROM users 
WHERE is_admin = false;
