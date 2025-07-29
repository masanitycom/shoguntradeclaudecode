-- 緊急システム復旧（最小限の機能で動作確認）

-- 1. 基本的なシステム状態確認
SELECT '🏥 システム基本状態確認' as section;

SELECT 
    'users' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN name IS NOT NULL THEN 1 END) as named_users,
    COUNT(CASE WHEN current_rank IS NOT NULL THEN 1 END) as with_rank
FROM users
UNION ALL
SELECT 
    'user_nfts' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_records,
    SUM(CASE WHEN is_active = true THEN purchase_price ELSE 0 END) as total_investment
FROM user_nfts
UNION ALL
SELECT 
    'nfts' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_nfts,
    0 as placeholder
FROM nfts
UNION ALL
SELECT 
    'mlm_ranks' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN rank_level > 0 THEN 1 END) as active_ranks,
    0 as placeholder
FROM mlm_ranks;

-- 2. 今日の日利計算を実行（基本版）
SELECT '💰 今日の日利計算実行' as section;

-- 今日の日利計算を強制実行
SELECT * FROM calculate_daily_rewards_batch(CURRENT_DATE);

-- 3. 今日の結果確認
SELECT 
    '📊 今日の日利計算結果' as info,
    COUNT(*) as total_rewards,
    SUM(reward_amount) as total_amount,
    COUNT(DISTINCT user_id) as unique_users,
    AVG(reward_amount) as avg_reward
FROM daily_rewards 
WHERE reward_date = CURRENT_DATE;

-- 4. ユーザー別今日の報酬
SELECT 
    '🏆 今日の報酬上位ユーザー' as info,
    u.name,
    u.current_rank,
    COUNT(dr.id) as nft_count,
    SUM(dr.reward_amount) as total_daily_reward
FROM users u
JOIN daily_rewards dr ON u.id = dr.user_id
WHERE dr.reward_date = CURRENT_DATE
AND u.name IS NOT NULL
GROUP BY u.id, u.name, u.current_rank
ORDER BY total_daily_reward DESC
LIMIT 10;

-- 5. 週利設定確認
SELECT '📈 週利設定確認' as section;

SELECT 
    drg.group_name,
    drg.daily_rate_limit * 100 as daily_rate_limit_percent,
    COUNT(gwr.id) as weekly_rate_records
FROM daily_rate_groups drg
LEFT JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;

-- 6. システムヘルスチェック（簡易版）
SELECT '🏥 システムヘルスチェック' as section;

SELECT 
    'データ整合性' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM user_nfts un
            LEFT JOIN users u ON un.user_id = u.id
            WHERE u.id IS NULL
        ) THEN '❌ 孤立レコードあり'
        ELSE '✅ データ整合性OK'
    END as status
UNION ALL
SELECT 
    '今日の日利計算' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM daily_rewards 
            WHERE reward_date = CURRENT_DATE
        ) THEN '✅ 今日の日利計算済み'
        ELSE '❌ 今日の日利計算未実行'
    END as status
UNION ALL
SELECT 
    'MLMランク設定' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM mlm_ranks 
            WHERE rank_level > 0
        ) THEN '✅ MLMランク設定済み'
        ELSE '❌ MLMランク未設定'
    END as status;

-- 7. 最終ステータス
SELECT 
    '✅ 緊急システム復旧完了' as final_status,
    NOW() as recovery_completed_at,
    (SELECT COUNT(*) FROM users WHERE name IS NOT NULL) as total_users,
    (SELECT COUNT(*) FROM user_nfts WHERE is_active = true) as active_nfts,
    (SELECT COUNT(*) FROM daily_rewards WHERE reward_date = CURRENT_DATE) as today_rewards,
    (SELECT COUNT(*) FROM mlm_ranks WHERE rank_level > 0) as active_ranks;
