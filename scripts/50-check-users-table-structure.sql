-- usersテーブルの現在の構造を確認

SELECT 'current_users_table_structure' as step;

SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 必要なカラムの存在確認
SELECT 'checking_required_columns' as step;

SELECT 
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'referral_code'
    ) THEN '✅ referral_code exists' 
    ELSE '❌ referral_code missing' END as referral_code_status,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'my_referral_code'
    ) THEN '✅ my_referral_code exists' 
    ELSE '❌ my_referral_code missing' END as my_referral_code_status,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'referral_link'
    ) THEN '✅ referral_link exists' 
    ELSE '❌ referral_link missing' END as referral_link_status,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'wallet_address'
    ) THEN '✅ wallet_address exists' 
    ELSE '❌ wallet_address missing' END as wallet_address_status,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'wallet_type'
    ) THEN '✅ wallet_type exists' 
    ELSE '❌ wallet_type missing' END as wallet_type_status;
