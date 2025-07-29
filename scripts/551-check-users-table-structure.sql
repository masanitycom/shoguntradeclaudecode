-- usersテーブルの実際の構造を確認

SELECT 
    '📋 usersテーブルの構造確認' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- mlm_ranksテーブルの構造も確認
SELECT 
    '📋 mlm_ranksテーブルの構造確認' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'mlm_ranks' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- daily_rate_groupsテーブルの構造も確認
SELECT 
    '📋 daily_rate_groupsテーブルの構造確認' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'daily_rate_groups' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- group_weekly_ratesテーブルの構造も確認
SELECT 
    '📋 group_weekly_ratesテーブルの構造確認' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- daily_rewardsテーブルの構造も確認
SELECT 
    '📋 daily_rewardsテーブルの構造確認' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- user_nftsテーブルの構造も確認
SELECT 
    '📋 user_nftsテーブルの構造確認' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_nfts' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- nftsテーブルの構造も確認
SELECT 
    '📋 nftsテーブルの構造確認' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'nfts' 
AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT '✅ 全テーブル構造確認完了' as final_status;
