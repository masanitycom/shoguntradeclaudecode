-- 日利計算結果の完全な確認

-- 1. 最新の日利計算結果を確認
SELECT 
    '📊 最新の日利計算結果' as result_info,
    COUNT(*) as total_records,
    MIN(reward_date) as earliest_date,
    MAX(reward_date) as latest_date,
    SUM(reward_amount) as total_rewards,
    AVG(reward_amount) as avg_reward,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT nft_id) as unique_nfts
FROM daily_rewards
WHERE created_at >= CURRENT_DATE;

-- 2. ユーザー別の日利計算結果
SELECT 
    '👤 ユーザー別日利計算結果' as user_info,
    u.name as user_name,
    COUNT(dr.id) as reward_count,
    SUM(dr.reward_amount) as total_rewards,
    AVG(dr.daily_rate) as avg_daily_rate,
    MIN(dr.reward_date) as first_reward_date,
    MAX(dr.reward_date) as last_reward_date
FROM daily_rewards dr
JOIN users u ON dr.user_id = u.id
WHERE dr.created_at >= CURRENT_DATE
GROUP BY u.id, u.name
ORDER BY total_rewards DESC
LIMIT 10;

-- 3. NFT別集計
SELECT 
    '🎯 NFT別日利集計' as info,
    n.name as nft_name,
    n.daily_rate_limit,
    COUNT(dr.id) as reward_count,
    SUM(dr.reward_amount) as total_rewards,
    AVG(dr.daily_rate) as avg_daily_rate,
    COUNT(DISTINCT dr.user_id) as unique_users
FROM daily_rewards dr
INNER JOIN nfts n ON dr.nft_id = n.id
WHERE dr.created_at >= CURRENT_DATE
GROUP BY n.id, n.name, n.daily_rate_limit
ORDER BY total_rewards DESC;

-- 4. 日付別集計
SELECT 
    '📅 日付別日利集計' as info,
    reward_date,
    COUNT(*) as reward_count,
    SUM(reward_amount) as daily_total,
    AVG(reward_amount) as daily_average,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT nft_id) as unique_nfts
FROM daily_rewards
WHERE reward_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY reward_date
ORDER BY reward_date DESC;

-- 5. user_nftsの更新状況確認
SELECT 
    '💰 user_nfts更新状況' as info,
    COUNT(*) as total_nfts,
    COUNT(CASE WHEN total_earned > 0 THEN 1 END) as nfts_with_earnings,
    SUM(total_earned) as total_all_earnings,
    AVG(total_earned) as avg_earnings,
    COUNT(CASE WHEN total_earned >= purchase_price * 3 THEN 1 END) as completed_nfts,
    COUNT(CASE WHEN total_earned >= purchase_price * 2.5 THEN 1 END) as near_completion_nfts
FROM user_nfts 
WHERE is_active = true;

-- 6. 300%キャップ状況
SELECT 
    '🎯 300%キャップ状況' as info,
    u.id,
    COALESCE(u.name, u.email, u.id::text) as user_name,
    n.name as nft_name,
    un.purchase_price,
    un.total_earned,
    ROUND((un.total_earned / un.purchase_price * 100)::numeric, 2) as completion_percentage,
    (un.purchase_price * 3 - un.total_earned) as remaining_to_cap
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true
AND un.total_earned > 0
ORDER BY completion_percentage DESC
LIMIT 20;

-- 7. エラーチェック
SELECT 
    '⚠️ 重複チェック' as info,
    user_nft_id,
    reward_date,
    COUNT(*) as duplicate_count
FROM daily_rewards 
WHERE reward_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY user_nft_id, reward_date
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 8. 週利データの確認
SELECT 
    '📈 週利データ確認' as info,
    drg.group_name,
    gwr.week_start_date,
    gwr.weekly_rate,
    gwr.monday_rate,
    gwr.tuesday_rate,
    gwr.wednesday_rate,
    gwr.thursday_rate,
    gwr.friday_rate,
    gwr.distribution_method
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date >= CURRENT_DATE - INTERVAL '4 weeks'
ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit;

-- 9. システム全体の健全性チェック
SELECT 
    '🔍 システム健全性チェック' as health_check,
    'daily_rewards' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN reward_amount > 0 THEN 1 END) as positive_rewards,
    COUNT(CASE WHEN daily_rate > 0 THEN 1 END) as positive_rates,
    COUNT(CASE WHEN is_claimed = true THEN 1 END) as claimed_rewards,
    COUNT(CASE WHEN is_claimed = false THEN 1 END) as unclaimed_rewards
FROM daily_rewards;
