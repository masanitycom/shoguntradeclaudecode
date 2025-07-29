-- 最終システム検証（動作確認）

-- 1. 全体システム状況
SELECT '🎯 最終システム状況' as section;

-- ユーザー統計
SELECT 
    '👥 ユーザー統計' as category,
    COUNT(*) as total_users,
    COUNT(CASE WHEN name IS NOT NULL THEN 1 END) as named_users,
    COUNT(CASE WHEN current_rank != 'なし' OR current_rank IS NULL THEN 1 END) as users_with_rank,
    COUNT(CASE WHEN total_earned > 0 THEN 1 END) as users_with_earnings
FROM users;

-- NFT投資統計
SELECT 
    '💎 NFT投資統計' as category,
    COUNT(*) as total_nft_investments,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_investments,
    SUM(CASE WHEN is_active = true THEN purchase_price ELSE 0 END) as total_active_investment,
    SUM(CASE WHEN is_active = true THEN COALESCE(total_earned, 0) ELSE 0 END) as total_earnings
FROM user_nfts;

-- 今日の日利統計
SELECT 
    '💰 今日の日利統計' as category,
    COUNT(*) as total_daily_rewards,
    SUM(reward_amount) as total_reward_amount,
    COUNT(DISTINCT user_id) as users_with_rewards,
    AVG(reward_amount) as avg_reward_amount
FROM daily_rewards 
WHERE reward_date = CURRENT_DATE;

-- 2. ランク別統計
SELECT '👑 ランク別統計' as section;

SELECT 
    COALESCE(current_rank, 'なし') as rank_name,
    COALESCE(current_rank_level, 0) as rank_level,
    COUNT(*) as user_count,
    SUM(COALESCE(total_earned, 0)) as total_earnings,
    AVG(COALESCE(total_earned, 0)) as avg_earnings
FROM users 
WHERE name IS NOT NULL
GROUP BY current_rank, current_rank_level
ORDER BY COALESCE(current_rank_level, 0) DESC;

-- 3. 今日の報酬上位ユーザー
SELECT '🏆 今日の報酬上位ユーザー' as section;

SELECT 
    u.name,
    COALESCE(u.current_rank, 'なし') as current_rank,
    COUNT(dr.id) as nft_count,
    SUM(dr.reward_amount) as today_reward,
    COALESCE(u.total_earned, 0) as total_earned
FROM users u
JOIN daily_rewards dr ON u.id = dr.user_id
WHERE dr.reward_date = CURRENT_DATE
AND u.name IS NOT NULL
GROUP BY u.id, u.name, u.current_rank, u.total_earned
ORDER BY today_reward DESC
LIMIT 15;

-- 4. NFT別パフォーマンス
SELECT '📈 NFT別パフォーマンス' as section;

SELECT 
    n.name as nft_name,
    n.price,
    n.daily_rate_limit * 100 as daily_rate_limit_percent,
    COUNT(un.id) as total_investments,
    COUNT(CASE WHEN un.is_active = true THEN 1 END) as active_investments,
    SUM(CASE WHEN un.is_active = true THEN un.purchase_price ELSE 0 END) as total_investment,
    SUM(CASE WHEN un.is_active = true THEN COALESCE(un.total_earned, 0) ELSE 0 END) as total_earned
FROM nfts n
LEFT JOIN user_nfts un ON n.id = un.nft_id
WHERE n.is_active = true
GROUP BY n.id, n.name, n.price, n.daily_rate_limit
ORDER BY total_investment DESC;

-- 5. 週利設定状況
SELECT '📊 週利設定状況' as section;

SELECT 
    drg.group_name,
    drg.daily_rate_limit * 100 as daily_rate_limit_percent,
    COUNT(gwr.id) as weekly_rate_settings,
    MAX(gwr.week_start_date) as latest_week_start
FROM daily_rate_groups drg
LEFT JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;

-- 6. システム健全性チェック
SELECT '🏥 システム健全性チェック' as section;

SELECT 
    'ユーザーデータ整合性' as check_item,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM user_nfts un
            LEFT JOIN users u ON un.user_id = u.id
            WHERE u.id IS NULL
        ) THEN '❌ 孤立レコードあり'
        ELSE '✅ 整合性OK'
    END as status
UNION ALL
SELECT 
    'NFTデータ整合性' as check_item,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM user_nfts un
            LEFT JOIN nfts n ON un.nft_id = n.id
            WHERE n.id IS NULL
        ) THEN '❌ 孤立レコードあり'
        ELSE '✅ 整合性OK'
    END as status
UNION ALL
SELECT 
    '今日の日利計算' as check_item,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM daily_rewards 
            WHERE reward_date = CURRENT_DATE
        ) THEN '✅ 計算済み'
        ELSE '❌ 未計算'
    END as status
UNION ALL
SELECT 
    'MLMランク設定' as check_item,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM mlm_ranks 
            WHERE rank_level > 0
        ) THEN '✅ 設定済み'
        ELSE '❌ 未設定'
    END as status
UNION ALL
SELECT 
    '週利設定' as check_item,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM group_weekly_rates 
            WHERE week_start_date >= CURRENT_DATE - INTERVAL '7 days'
        ) THEN '✅ 最近の設定あり'
        ELSE '⚠️ 古い設定のみ'
    END as status;

-- 7. 最終確認
SELECT 
    '🎉 システム最終確認完了' as final_status,
    NOW() as verification_time,
    EXTRACT(DOW FROM CURRENT_DATE) as day_of_week,
    CASE 
        WHEN EXTRACT(DOW FROM CURRENT_DATE) BETWEEN 1 AND 5 THEN '平日（計算可能）'
        ELSE '土日（計算停止）'
    END as calculation_status,
    (SELECT COUNT(*) FROM users WHERE name IS NOT NULL) as total_active_users,
    (SELECT COUNT(*) FROM user_nfts WHERE is_active = true) as total_active_nfts,
    (SELECT COALESCE(SUM(reward_amount), 0) FROM daily_rewards WHERE reward_date = CURRENT_DATE) as today_total_rewards;
