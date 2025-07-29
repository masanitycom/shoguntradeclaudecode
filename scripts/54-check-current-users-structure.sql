-- 現在のusersテーブル構造を確認

SELECT '=== 現在のUSERSテーブル構造 ===' as section;

SELECT 
    column_name, 
    data_type, 
    character_maximum_length,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT '=== 不足しているカラムの確認 ===' as section;

-- 必要なカラムの存在確認
SELECT 
    'referral_code' as column_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'referral_code'
    ) THEN '✅ 存在' ELSE '❌ 不足' END as status
UNION ALL
SELECT 
    'my_referral_code' as column_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'my_referral_code'
    ) THEN '✅ 存在' ELSE '❌ 不足' END as status
UNION ALL
SELECT 
    'referral_link' as column_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'referral_link'
    ) THEN '✅ 存在' ELSE '❌ 不足' END as status
UNION ALL
SELECT 
    'wallet_address' as column_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'wallet_address'
    ) THEN '✅ 存在' ELSE '❌ 不足' END as status
UNION ALL
SELECT 
    'wallet_type' as column_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'wallet_type'
    ) THEN '✅ 存在' ELSE '❌ 不足' END as status;
