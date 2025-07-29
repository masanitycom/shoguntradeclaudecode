-- 日利計算システムのテスト実行

-- 1. 計算前の状態確認
SELECT 
    '=== 計算前の状態確認 ===' as section,
    COUNT(*) as total_active_nfts,
    COUNT(DISTINCT user_id) as total_users,
    SUM(purchase_price) as total_investment,
    SUM(total_earned) as current_total_earned
FROM user_nfts 
WHERE is_active = true;

-- 2. 週利設定の確認
SELECT 
    '=== 週利設定確認 ===' as section,
    week_start_date,
    group_name,
    (weekly_rate * 100)::numeric(5,2) as weekly_rate_percent,
    (monday_rate * 100)::numeric(5,2) as monday_percent,
    distribution_method
FROM group_weekly_rates
WHERE week_start_date IN ('2025-02-10', '2025-02-17')
ORDER BY week_start_date, group_name;

-- 3. NFTとグループの対応確認
SELECT 
    '=== NFTグループ対応確認 ===' as section,
    n.name as nft_name,
    n.daily_rate_limit,
    drg.group_name,
    COUNT(un.id) as nft_count,
    SUM(un.purchase_price) as total_investment
FROM user_nfts un
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
WHERE un.is_active = true
AND (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date = '2025-02-10'
GROUP BY n.name, n.daily_rate_limit, drg.group_name
ORDER BY n.daily_rate_limit;

-- 4. 2025-02-10（月曜日）の日利計算実行
SELECT 
    '=== 日利計算実行 ===' as section,
    success,
    message,
    processed_count,
    total_amount
FROM calculate_daily_rewards('2025-02-10'::date);

-- 5. 計算結果の詳細確認
SELECT 
    '=== 計算結果詳細 ===' as section,
    u.name as user_name,
    n.name as nft_name,
    un.purchase_price,
    (dr.weekly_rate * 100)::numeric(5,2) as weekly_rate_percent,
    (dr.daily_rate * 100)::numeric(5,2) as daily_rate_percent,
    dr.reward_amount,
    dr.reward_date,
    dr.is_claimed
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN users u ON dr.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE dr.reward_date = '2025-02-10'
ORDER BY dr.reward_amount DESC
LIMIT 20;

-- 6. グループ別統計
SELECT 
    '=== グループ別統計 ===' as section,
    drg.group_name,
    COUNT(dr.id) as reward_count,
    SUM(dr.reward_amount) as total_rewards,
    AVG(dr.reward_amount) as avg_reward,
    MIN(dr.reward_amount) as min_reward,
    MAX(dr.reward_amount) as max_reward
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
WHERE dr.reward_date = '2025-02-10'
GROUP BY drg.group_name
ORDER BY total_rewards DESC;

-- 7. 統計関数のテスト
SELECT 
    '=== 統計関数テスト ===' as section,
    reward_date,
    total_rewards,
    total_amount,
    avg_amount,
    unique_users,
    group_breakdown
FROM get_daily_calculation_stats('2025-02-10'::date);

-- 8. ユーザーダッシュボード用データ確認（上位10ユーザー）
SELECT 
    '=== ユーザーダッシュボード確認 ===' as section,
    u.name as user_name,
    COUNT(dr.id) as nft_count,
    SUM(un.purchase_price) as total_investment,
    SUM(dr.reward_amount) as daily_reward,
    SUM(un.total_earned) as total_earned_after_update
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN users u ON dr.user_id = u.id
WHERE dr.reward_date = '2025-02-10'
GROUP BY u.id, u.name
ORDER BY daily_reward DESC
LIMIT 10;

-- 9. 全体統計サマリー
SELECT 
    '=== 全体統計サマリー ===' as section,
    dr.reward_date,
    COUNT(*) as total_rewards,
    SUM(dr.reward_amount) as total_amount,
    AVG(dr.reward_amount) as avg_amount,
    MIN(dr.reward_amount) as min_amount,
    MAX(dr.reward_amount) as max_amount,
    COUNT(DISTINCT dr.user_id) as unique_users
FROM daily_rewards dr
WHERE dr.reward_date = '2025-02-10'
GROUP BY dr.reward_date;
