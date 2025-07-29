-- 最終的なテーブル構造確認

SELECT '=== 最終的なUSERSテーブル構造 ===' as section;

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

SELECT '=== サンプルデータ確認 ===' as section;

-- 最新の3ユーザーのデータ確認
SELECT 
    name,
    user_id,
    email,
    referral_code,
    my_referral_code,
    wallet_type,
    is_admin,
    created_at
FROM users 
ORDER BY created_at DESC 
LIMIT 3;

SELECT '=== 統計情報 ===' as section;

SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN is_admin = true THEN 1 END) as admin_users,
    COUNT(CASE WHEN is_admin = false THEN 1 END) as regular_users,
    COUNT(referral_code) as users_with_referral_code,
    COUNT(my_referral_code) as users_with_my_referral_code,
    COUNT(wallet_address) as users_with_wallet_address
FROM users;
