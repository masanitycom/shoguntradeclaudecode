-- 週利システムの現在の状況を確認

-- 1. 日利上限グループの確認
SELECT 
    'Daily Rate Groups Status' as check_type,
    drg.group_name,
    drg.daily_rate_limit,
    drg.description,
    COUNT(n.id) as nft_count
FROM daily_rate_groups drg
LEFT JOIN nfts n ON drg.id = n.group_id
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit, drg.description
ORDER BY drg.daily_rate_limit;

-- 2. 過去の週利履歴の確認
SELECT 
    'Historical Weekly Rates Status' as check_type,
    COUNT(*) as total_historical_records,
    MIN(week_number) as earliest_week,
    MAX(week_number) as latest_week,
    COUNT(DISTINCT nft_id) as unique_nfts_with_history
FROM nft_weekly_rates;

-- 3. 現在の週利設定の確認
SELECT 
    'Current Weekly Rates Status' as check_type,
    gwr.week_number,
    drg.group_name,
    gwr.weekly_rate,
    gwr.week_start_date
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
ORDER BY gwr.week_number DESC, drg.group_name
LIMIT 20;

-- 4. NFTのグループ分類状況
SELECT 
    'NFT Group Classification' as check_type,
    n.name,
    n.daily_rate_limit,
    drg.group_name,
    CASE WHEN n.group_id IS NULL THEN 'NOT_CLASSIFIED' ELSE 'CLASSIFIED' END as status
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.group_id = drg.id
ORDER BY n.daily_rate_limit, n.name;

-- 5. 最新の日利報酬データ
SELECT 
    'Latest Daily Rewards' as check_type,
    COUNT(*) as total_rewards,
    MAX(reward_date) as latest_reward_date,
    SUM(reward_amount) as total_amount
FROM daily_rewards
WHERE reward_date >= CURRENT_DATE - INTERVAL '7 days';
