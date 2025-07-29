-- 更新後の構造とデータを確認

SELECT '=== 更新後のUSERSテーブル構造 ===' as section;

SELECT 
    column_name, 
    data_type, 
    character_maximum_length,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT '=== 紹介機能の統計 ===' as section;

SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN is_admin = false THEN 1 END) as regular_users,
    COUNT(referrer_id) as users_with_referrer,
    COUNT(my_referral_code) as users_with_my_referral_code,
    COUNT(referral_link) as users_with_referral_link
FROM users;

SELECT '=== サンプルデータ（最新3件）===' as section;

SELECT 
    name,
    user_id,
    email,
    CASE WHEN referrer_id IS NOT NULL THEN '有り' ELSE 'なし' END as has_referrer,
    my_referral_code,
    wallet_type,
    is_admin
FROM users 
ORDER BY created_at DESC 
LIMIT 3;

SELECT '=== 紹介関係の確認 ===' as section;

-- 紹介者がいるユーザーの例
SELECT 
    u.name as user_name,
    u.user_id as user_id,
    r.name as referrer_name,
    r.user_id as referrer_user_id,
    u.my_referral_code
FROM users u
JOIN users r ON u.referrer_id = r.id
WHERE u.is_admin = false
LIMIT 5;
