-- daily_rewardsテーブルの構造確認

SELECT 
    '=== daily_rewards テーブル構造 ===' as section,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- usersテーブルの構造も確認
SELECT 
    '=== users テーブル構造 ===' as section,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- group_weekly_ratesテーブルの構造確認
SELECT 
    '=== group_weekly_rates テーブル構造 ===' as section,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates' 
AND table_schema = 'public'
ORDER BY ordinal_position;
