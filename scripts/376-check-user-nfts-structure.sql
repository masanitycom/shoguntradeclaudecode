-- user_nftsテーブルの構造確認
SELECT 
    '📋 user_nftsテーブル構造確認' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_nfts' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- nftsテーブルの構造確認
SELECT 
    '📋 nftsテーブル構造確認' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'nfts' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- daily_rate_groupsテーブルの構造確認
SELECT 
    '📋 daily_rate_groupsテーブル構造確認' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'daily_rate_groups' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- group_weekly_ratesテーブルの構造確認
SELECT 
    '📋 group_weekly_ratesテーブル構造確認' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates' 
AND table_schema = 'public'
ORDER BY ordinal_position;
