-- 正しい週利で再計算

-- 1. 今日の既存報酬をクリア
DELETE FROM daily_rewards WHERE reward_date = CURRENT_DATE;

-- 2. 修正された計算関数で再計算
SELECT * FROM force_daily_calculation();

-- 3. 計算結果の詳細確認
SELECT 
    '修正後の計算結果' as status,
    COUNT(*) as total_rewards,
    SUM(reward_amount) as total_amount,
    AVG(reward_amount) as avg_reward,
    MIN(reward_amount) as min_reward,
    MAX(reward_amount) as max_reward,
    COUNT(DISTINCT user_id) as unique_users
FROM daily_rewards 
WHERE reward_date = CURRENT_DATE;

-- 4. グループ別の報酬確認
SELECT 
    CASE 
        WHEN n.price <= 100 THEN '0.5%グループ'
        WHEN n.price <= 300 THEN '1.0%グループ'
        WHEN n.price <= 500 THEN '1.25%グループ'
        WHEN n.price <= 1000 THEN '1.5%グループ'
        WHEN n.price <= 1500 THEN '1.75%グループ'
        ELSE '2.0%グループ'
    END as nft_group,
    COUNT(dr.id) as reward_count,
    SUM(dr.reward_amount) as group_total,
    AVG(dr.reward_amount) as group_avg,
    AVG(un.purchase_price) as avg_investment,
    AVG(dr.daily_rate * 100) as avg_daily_rate_percent
FROM daily_rewards dr
JOIN nfts n ON dr.nft_id = n.id
JOIN user_nfts un ON dr.user_nft_id = un.id
WHERE dr.reward_date = CURRENT_DATE
GROUP BY 
    CASE 
        WHEN n.price <= 100 THEN '0.5%グループ'
        WHEN n.price <= 300 THEN '1.0%グループ'
        WHEN n.price <= 500 THEN '1.25%グループ'
        WHEN n.price <= 1000 THEN '1.5%グループ'
        WHEN n.price <= 1500 THEN '1.75%グループ'
        ELSE '2.0%グループ'
    END
ORDER BY 
    CASE 
        WHEN n.price <= 100 THEN 1
        WHEN n.price <= 300 THEN 2
        WHEN n.price <= 500 THEN 3
        WHEN n.price <= 1000 THEN 4
        WHEN n.price <= 1500 THEN 5
        ELSE 6
    END;

-- 5. 上位ユーザーの報酬確認
SELECT 
    u.name,
    COUNT(dr.id) as nft_count,
    SUM(dr.reward_amount) as total_reward,
    SUM(un.purchase_price) as total_investment,
    ROUND((SUM(dr.reward_amount) / SUM(un.purchase_price) * 100)::numeric, 4) as actual_daily_rate_percent
FROM daily_rewards dr
JOIN users u ON dr.user_id = u.id
JOIN user_nfts un ON dr.user_nft_id = un.id
WHERE dr.reward_date = CURRENT_DATE
GROUP BY u.id, u.name
ORDER BY total_reward DESC
LIMIT 15;

-- 6. 計算の正確性確認
SELECT 
    '計算正確性チェック' as check_type,
    dr.reward_amount,
    un.purchase_price,
    dr.daily_rate,
    (un.purchase_price * dr.daily_rate) as expected_reward,
    CASE 
        WHEN ABS(dr.reward_amount - (un.purchase_price * dr.daily_rate)) < 0.01 THEN '正確'
        ELSE '不正確'
    END as accuracy_status
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
WHERE dr.reward_date = CURRENT_DATE
ORDER BY dr.reward_amount DESC
LIMIT 10;
