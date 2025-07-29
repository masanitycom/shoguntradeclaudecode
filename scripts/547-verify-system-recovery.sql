-- システム復旧の確認

-- 1. 最新の日利計算結果を確認
SELECT 
    '📊 最新日利計算結果' as info,
    COUNT(*) as total_records,
    SUM(reward_amount) as total_rewards,
    MAX(created_at) as latest_calculation
FROM daily_rewards
WHERE reward_date = CURRENT_DATE;

-- 2. ユーザー別の最新状況
SELECT 
    '👤 ユーザー別最新状況' as info,
    u.name as user_name,
    COUNT(un.id) as nft_count,
    SUM(un.purchase_price) as total_investment,
    SUM(un.total_earned) as total_earned,
    COUNT(dr.id) as todays_rewards
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
LEFT JOIN daily_rewards dr ON u.id = dr.user_id AND dr.reward_date = CURRENT_DATE
WHERE u.name IS NOT NULL
GROUP BY u.id, u.name
HAVING COUNT(un.id) > 0
ORDER BY total_earned DESC
LIMIT 10;

-- 3. user_nftsの更新状況
SELECT 
    '🔄 user_nfts更新状況' as info,
    COUNT(*) as total_active_nfts,
    COUNT(CASE WHEN DATE(updated_at) = CURRENT_DATE THEN 1 END) as updated_today,
    SUM(total_earned) as total_all_earnings,
    AVG(total_earned) as avg_earnings
FROM user_nfts 
WHERE is_active = true;

-- 4. MLMランク計算テスト
SELECT 
    '🎯 MLMランク計算テスト' as info,
    *
FROM calculate_user_mlm_rank('deaa37bc-cc8e-4225-866e-a31e22fd4efe'::UUID)
LIMIT 1;

-- 5. 週利設定の状況確認
SELECT 
    '📈 週利設定状況' as info,
    COUNT(*) as total_weekly_rates,
    COUNT(CASE WHEN week_start_date >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as recent_rates
FROM group_weekly_rates;

-- 6. システム全体の健全性
SELECT 
    '🔍 システム健全性' as info,
    'users' as table_name,
    COUNT(*) as record_count
FROM users
UNION ALL
SELECT 
    '🔍 システム健全性' as info,
    'user_nfts' as table_name,
    COUNT(*) as record_count
FROM user_nfts
UNION ALL
SELECT 
    '🔍 システム健全性' as info,
    'daily_rewards' as table_name,
    COUNT(*) as record_count
FROM daily_rewards
UNION ALL
SELECT 
    '🔍 システム健全性' as info,
    'group_weekly_rates' as table_name,
    COUNT(*) as record_count
FROM group_weekly_rates;
