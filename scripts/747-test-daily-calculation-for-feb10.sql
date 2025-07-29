-- 2025-02-10週の日利計算テスト

-- 1. 計算前の状態確認
SELECT 
    '=== 計算前の状態 ===' as section,
    COUNT(*) as total_nfts,
    COUNT(DISTINCT user_id) as total_users,
    SUM(purchase_price) as total_investment,
    SUM(total_earned) as current_total_earned
FROM user_nfts 
WHERE is_active = true
AND (operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date = '2025-02-10';

-- 2. 週利設定の確認
SELECT 
    '=== 週利設定確認 ===' as section,
    group_name,
    weekly_rate,
    monday_rate,
    tuesday_rate,
    wednesday_rate,
    thursday_rate,
    friday_rate
FROM group_weekly_rates
WHERE week_start_date = '2025-02-10'
ORDER BY group_name;

-- 3. テスト用日利計算実行（2025-02-10の月曜日）
SELECT calculate_daily_rewards('2025-02-10'::date) as calculation_result;

-- 4. 計算結果の確認
SELECT 
    '=== 計算結果確認 ===' as section,
    u.name as user_name,
    n.name as nft_name,
    dr.reward_date,
    dr.weekly_rate,
    dr.daily_rate,
    dr.reward_amount,
    dr.is_claimed
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN users u ON dr.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE dr.reward_date = '2025-02-10'
ORDER BY dr.reward_amount DESC
LIMIT 10;

-- 5. 統計サマリー
SELECT 
    '=== 計算統計 ===' as section,
    reward_date,
    COUNT(*) as total_rewards,
    SUM(reward_amount) as total_amount,
    AVG(reward_amount) as avg_amount,
    MIN(reward_amount) as min_amount,
    MAX(reward_amount) as max_amount
FROM daily_rewards
WHERE reward_date = '2025-02-10'
GROUP BY reward_date;
