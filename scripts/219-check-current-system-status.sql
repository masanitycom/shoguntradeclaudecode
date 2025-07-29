-- 現在のシステム状態を包括的にチェック

-- 1. 主要テーブルの存在確認
SELECT 
    'Table Existence Check' as check_type,
    table_name,
    'EXISTS' as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'users', 'nfts', 'user_nfts', 'daily_rewards', 
    'weekly_rates', 'daily_rate_groups', 'mlm_ranks',
    'tenka_bonus_distributions', 'tasks', 'reward_applications'
)
ORDER BY table_name;

-- 2. NFTsテーブルの構造確認
SELECT 
    'NFTs Table Structure' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'nfts' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. 現在のNFT分類状況
SELECT 
    'Current NFT Classification' as check_type,
    n.name,
    n.price,
    n.daily_rate_limit,
    n.is_special,
    n.group_id,
    drg.group_name,
    drg.daily_rate_limit as group_limit
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.group_id = drg.id
ORDER BY n.price;

-- 4. 日利グループの状況
SELECT 
    'Daily Rate Groups' as check_type,
    id,
    group_name,
    daily_rate_limit,
    description
FROM daily_rate_groups 
ORDER BY daily_rate_limit;

-- 5. ユーザー数とNFT保有状況
SELECT 
    'User and NFT Status' as check_type,
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM nfts) as total_nfts,
    (SELECT COUNT(*) FROM user_nfts) as total_user_nfts,
    (SELECT COUNT(*) FROM daily_rewards) as total_daily_rewards;

-- 6. 週利システムの状況
SELECT 
    'Weekly Rates System' as check_type,
    COUNT(*) as total_weekly_rates,
    MIN(week_start_date) as earliest_week,
    MAX(week_start_date) as latest_week
FROM weekly_rates;

-- 7. MLMランクシステムの状況
SELECT 
    'MLM Rank System' as check_type,
    COUNT(*) as total_rank_definitions
FROM mlm_ranks;

-- 8. 重要な関数の存在確認
SELECT 
    'Function Existence' as check_type,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN (
    'calculate_daily_rewards',
    'process_compound_interest',
    'determine_user_rank',
    'distribute_tenka_bonus'
)
ORDER BY routine_name;
