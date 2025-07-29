-- 計算結果の検証

-- 1. トップユーザー確認
SELECT 
    'トップユーザー確認' as check_type,
    COALESCE(u.name, u.email, u.id::text) as user_name,
    COUNT(un.id) as nft_count,
    SUM(un.purchase_price) as total_investment,
    SUM(un.total_earned) as total_earned,
    ROUND(SUM(un.total_earned) / NULLIF(SUM(un.purchase_price), 0) * 100, 2) as completion_percentage,
    COUNT(CASE WHEN un.total_earned >= un.purchase_price * 3 THEN 1 END) as completed_nfts
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
GROUP BY u.id, u.name, u.email
HAVING SUM(un.purchase_price) > 0
ORDER BY total_earned DESC
LIMIT 10;

-- 2. 日利報酬サマリー
SELECT 
    '日利報酬サマリー' as check_type,
    COUNT(*) as total_rewards,
    SUM(reward_amount) as total_amount,
    MIN(reward_date) as earliest_date,
    MAX(reward_date) as latest_date,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT user_nft_id) as unique_nfts
FROM daily_rewards;

-- 3. 最近の報酬確認
SELECT 
    '最近の報酬確認' as check_type,
    reward_date,
    COUNT(*) as reward_count,
    SUM(reward_amount) as daily_total
FROM daily_rewards 
WHERE reward_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY reward_date
ORDER BY reward_date DESC;

-- 4. ユーザー別最新状況
SELECT 
    'ユーザー別最新状況' as check_type,
    COALESCE(u.name, u.email, u.id::text) as user_name,
    un.purchase_price,
    un.total_earned,
    ROUND(un.total_earned / un.purchase_price * 100, 2) as progress_percentage,
    CASE WHEN un.total_earned >= un.purchase_price * 3 THEN '完了' ELSE '進行中' END as status
FROM users u
JOIN user_nfts un ON u.id = un.user_id
WHERE un.is_active = true
ORDER BY un.total_earned DESC
LIMIT 20;

-- 5. 週利設定確認
SELECT 
    '週利設定確認' as check_type,
    drg.group_name,
    gwr.week_start_date,
    gwr.weekly_rate,
    gwr.monday_rate,
    gwr.tuesday_rate,
    gwr.wednesday_rate,
    gwr.thursday_rate,
    gwr.friday_rate
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit;
