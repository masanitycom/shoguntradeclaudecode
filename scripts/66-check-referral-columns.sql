-- referral_code カラムの存在確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('referral_code', 'my_referral_code', 'referral_link')
ORDER BY column_name;

-- 実際のテーブル構造確認
\d users;

-- サンプルデータ確認
SELECT 
    name,
    user_id,
    referral_code,
    my_referral_code,
    referral_link
FROM users 
WHERE user_id = 'pigret10'
LIMIT 1;
