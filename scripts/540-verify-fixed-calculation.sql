-- 修正版日利計算の結果確認

-- 1. 最新の日利報酬確認
SELECT 
    '📊 最新日利報酬' as info,
    COUNT(*) as total_rewards,
    SUM(reward_amount) as total_amount,
    AVG(reward_amount) as avg_amount,
    MAX(reward_date) as latest_date,
    MIN(reward_date) as earliest_date
FROM daily_rewards 
WHERE reward_date >= CURRENT_DATE - INTERVAL '7 days';

-- 2. 今日の日利報酬詳細
SELECT 
    '📅 今日の日利報酬詳細' as info,
    dr.reward_date,
    u.name as user_name,
    n.name as nft_name,
    dr.reward_amount,
    dr.daily_rate,
    dr.created_at
FROM daily_rewards dr
JOIN users u ON dr.user_id = u.id
JOIN nfts n ON dr.nft_id = n.id
WHERE dr.reward_date = CURRENT_DATE
ORDER BY dr.created_at DESC
LIMIT 10;

-- 3. ユーザー別累計確認
SELECT 
    '👥 ユーザー別累計' as info,
    u.name as user_name,
    COUNT(dr.id) as reward_count,
    SUM(dr.reward_amount) as total_rewards,
    MAX(dr.reward_date) as last_reward_date
FROM daily_rewards dr
JOIN users u ON dr.user_id = u.id
WHERE dr.reward_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY u.id, u.name
ORDER BY total_rewards DESC
LIMIT 10;

-- 4. user_nftsの更新状況確認
SELECT 
    '💰 user_nfts更新状況' as info,
    COUNT(*) as total_active_nfts,
    COUNT(CASE WHEN updated_at::date = CURRENT_DATE THEN 1 END) as updated_today,
    SUM(total_earned)::text as total_all_earnings,
    AVG(total_earned) as avg_earnings
FROM user_nfts 
WHERE is_active = true;
