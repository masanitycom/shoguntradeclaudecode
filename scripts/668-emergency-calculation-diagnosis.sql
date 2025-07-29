-- 緊急診断：現在のシステム状況を確認

-- 1. テーブル構造の確認
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('daily_rate_groups', 'group_weekly_rates', 'daily_rewards', 'user_nfts', 'nfts')
ORDER BY table_name, ordinal_position;

-- 2. 現在のグループ設定を確認
SELECT * FROM daily_rate_groups ORDER BY daily_rate_limit;

-- 3. NFTの設定状況を確認
SELECT 
    id,
    name,
    price,
    daily_rate_limit,
    (SELECT COUNT(*) FROM user_nfts WHERE nft_id = nfts.id AND is_active = true) as active_users
FROM nfts 
ORDER BY price;

-- 4. 週利設定の確認
SELECT 
    week_start_date,
    week_end_date,
    COUNT(*) as group_count
FROM group_weekly_rates 
GROUP BY week_start_date, week_end_date
ORDER BY week_start_date DESC
LIMIT 10;

-- 5. 現在の報酬状況
SELECT 
    COUNT(*) as total_rewards,
    SUM(reward_amount) as total_amount,
    COUNT(DISTINCT user_id) as unique_users,
    MAX(reward_date) as latest_date
FROM daily_rewards;

-- 6. 今日の計算状況
SELECT 
    COUNT(*) as today_rewards,
    SUM(reward_amount) as today_amount
FROM daily_rewards 
WHERE reward_date = CURRENT_DATE;
