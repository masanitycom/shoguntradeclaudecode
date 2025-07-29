-- ダッシュボードデータの検証

-- 1. テーブル構造の最終確認
SELECT 
    '🔍 テーブル構造確認' as check_type,
    'group_weekly_rates' as table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates'
ORDER BY ordinal_position;

-- 2. 日利報酬の集計確認
SELECT 
    '📈 日利報酬データ' as check_type,
    COUNT(*) as total_records,
    ROUND(SUM(reward_amount), 2) as total_rewards,
    MIN(reward_date) as earliest_date,
    MAX(reward_date) as latest_date,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT user_nft_id) as unique_nfts
FROM daily_rewards;

-- 3. ユーザー別報酬確認（詳細）
SELECT 
    '👥 ユーザー別報酬詳細' as check_type,
    u.display_name,
    COUNT(DISTINCT un.id) as nft_count,
    ROUND(SUM(un.purchase_price), 2) as total_investment,
    ROUND(SUM(un.total_earned), 2) as total_earned_from_nfts,
    ROUND(COALESCE(SUM(dr.reward_amount), 0), 2) as total_daily_rewards,
    COUNT(dr.id) as reward_count
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
LEFT JOIN daily_rewards dr ON u.id = dr.user_id
GROUP BY u.id, u.display_name
HAVING SUM(un.purchase_price) > 0
ORDER BY total_earned_from_nfts DESC
LIMIT 15;

-- 4. NFT別報酬確認
SELECT 
    '🎯 NFT別報酬' as check_type,
    n.name as nft_name,
    n.price,
    n.daily_rate_limit * 100 as daily_rate_limit_percent,
    COUNT(dr.id) as reward_count,
    ROUND(SUM(dr.reward_amount), 2) as total_rewards,
    ROUND(AVG(dr.daily_rate_used * 100), 3) as avg_daily_rate_percent
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
GROUP BY n.id, n.name, n.price, n.daily_rate_limit
ORDER BY total_rewards DESC;

-- 5. 週利設定確認
SELECT 
    '📅 週利設定' as check_type,
    drg.group_name,
    gwr.week_start_date,
    ROUND(gwr.weekly_rate * 100, 2) as weekly_rate_percent,
    ROUND(gwr.monday_rate * 100, 2) as monday_percent,
    ROUND(gwr.tuesday_rate * 100, 2) as tuesday_percent,
    ROUND(gwr.wednesday_rate * 100, 2) as wednesday_percent,
    ROUND(gwr.thursday_rate * 100, 2) as thursday_percent,
    ROUND(gwr.friday_rate * 100, 2) as friday_percent
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit;

-- 6. 最新の報酬計算日確認
SELECT 
    '⏰ 最新計算状況' as check_type,
    MAX(calculation_date) as latest_calculation,
    MAX(reward_date) as latest_reward_date,
    COUNT(DISTINCT reward_date) as unique_reward_dates,
    COUNT(DISTINCT DATE(calculation_date)) as calculation_days
FROM daily_rewards;

-- 7. 日別報酬サマリー
SELECT 
    '📊 日別報酬サマリー' as check_type,
    reward_date,
    COUNT(*) as reward_count,
    COUNT(DISTINCT user_id) as active_users,
    ROUND(SUM(reward_amount), 2) as daily_total,
    ROUND(AVG(reward_amount), 2) as avg_reward
FROM daily_rewards
WHERE reward_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY reward_date
ORDER BY reward_date DESC;

-- 8. システム健全性チェック
SELECT 
    '🏥 システム健全性' as check_type,
    (SELECT COUNT(*) FROM users WHERE is_admin = false) as total_users,
    (SELECT COUNT(*) FROM user_nfts WHERE is_active = true) as active_nfts,
    (SELECT COUNT(*) FROM daily_rewards) as total_rewards,
    (SELECT COUNT(*) FROM group_weekly_rates) as weekly_rate_settings,
    CASE 
        WHEN (SELECT COUNT(*) FROM daily_rewards) > 0 THEN '✅ 正常'
        ELSE '❌ 異常'
    END as status
;

RAISE NOTICE '✅ データ検証完了！';
