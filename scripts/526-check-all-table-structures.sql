-- 全テーブル構造の完全確認

-- 1. users テーブル構造
SELECT 
    '📋 users テーブル構造' as table_info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

-- 2. nfts テーブル構造
SELECT 
    '📋 nfts テーブル構造' as table_info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'nfts' 
ORDER BY ordinal_position;

-- 3. user_nfts テーブル構造
SELECT 
    '📋 user_nfts テーブル構造' as table_info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_nfts' 
ORDER BY ordinal_position;

-- 4. daily_rewards テーブル構造
SELECT 
    '📋 daily_rewards テーブル構造' as table_info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
ORDER BY ordinal_position;

-- 5. daily_rate_groups テーブル構造
SELECT 
    '📋 daily_rate_groups テーブル構造' as table_info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'daily_rate_groups' 
ORDER BY ordinal_position;

-- 6. group_weekly_rates テーブル構造
SELECT 
    '📋 group_weekly_rates テーブル構造' as table_info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates' 
ORDER BY ordinal_position;

-- 7. 既存データ確認
SELECT '📊 daily_rate_groups データ' as data_info, id, group_name, daily_rate_limit FROM daily_rate_groups ORDER BY daily_rate_limit;

SELECT '📊 group_weekly_rates データ' as data_info, COUNT(*) as record_count, MIN(week_start_date) as min_date, MAX(week_start_date) as max_date FROM group_weekly_rates;

SELECT '📊 user_nfts データ' as data_info, COUNT(*) as total_nfts, COUNT(CASE WHEN is_active THEN 1 END) as active_nfts FROM user_nfts;

SELECT '📊 daily_rewards データ' as data_info, COUNT(*) as total_rewards, MIN(reward_date) as min_date, MAX(reward_date) as max_date FROM daily_rewards;

-- 8. 外部キー制約確認
SELECT 
    '🔗 外部キー制約' as constraint_info,
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE contype = 'f' 
AND conrelid IN (
    'users'::regclass,
    'nfts'::regclass,
    'user_nfts'::regclass,
    'daily_rewards'::regclass,
    'daily_rate_groups'::regclass,
    'group_weekly_rates'::regclass
);
