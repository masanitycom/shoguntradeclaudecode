-- 🔍 実際のテーブル構造確認

-- 1. usersテーブル構造
SELECT '=== users テーブル構造 ===' as section;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

-- 2. user_nftsテーブル構造
SELECT '=== user_nfts テーブル構造 ===' as section;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'user_nfts' 
ORDER BY ordinal_position;

-- 3. nftsテーブル構造
SELECT '=== nfts テーブル構造 ===' as section;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'nfts' 
ORDER BY ordinal_position;

-- 4. daily_rewardsテーブル構造
SELECT '=== daily_rewards テーブル構造 ===' as section;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
ORDER BY ordinal_position;

-- 5. daily_rate_groupsテーブル構造
SELECT '=== daily_rate_groups テーブル構造 ===' as section;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'daily_rate_groups' 
ORDER BY ordinal_position;

-- 6. group_weekly_ratesテーブル構造
SELECT '=== group_weekly_rates テーブル構造 ===' as section;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates' 
ORDER BY ordinal_position;

-- 7. 既存の関数確認
SELECT '=== 既存関数確認 ===' as section;
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_name LIKE '%calculate%' 
AND routine_schema = 'public';
