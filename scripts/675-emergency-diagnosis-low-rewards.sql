-- 緊急診断：異常に低い報酬の原因調査

-- 1. 今日の報酬詳細を確認
SELECT 
    dr.user_id,
    u.name,
    dr.user_nft_id,
    dr.nft_id,
    n.name as nft_name,
    n.price as nft_price,
    un.purchase_price,
    dr.daily_rate,
    dr.reward_amount,
    n.daily_rate_limit
FROM daily_rewards dr
JOIN users u ON dr.user_id = u.id
JOIN nfts n ON dr.nft_id = n.id
JOIN user_nfts un ON dr.user_nft_id = un.id
WHERE dr.reward_date = CURRENT_DATE
ORDER BY dr.reward_amount DESC
LIMIT 20;

-- 2. 週利設定の確認
SELECT 
    week_start_date,
    group_name,
    weekly_rate,
    monday_rate,
    tuesday_rate,
    wednesday_rate,
    thursday_rate,
    friday_rate
FROM group_weekly_rates 
WHERE week_start_date = CURRENT_DATE - EXTRACT(DOW FROM CURRENT_DATE)::INTEGER + 1;

-- 3. NFTの日利上限設定確認
SELECT 
    id,
    name,
    price,
    daily_rate_limit,
    COUNT(un.id) as user_count
FROM nfts n
LEFT JOIN user_nfts un ON n.id = un.nft_id AND un.is_active = true
GROUP BY n.id, n.name, n.price, n.daily_rate_limit
ORDER BY n.price;

-- 4. 計算ロジックの問題を特定
SELECT 
    '計算問題の特定' as analysis,
    AVG(dr.daily_rate) as avg_daily_rate,
    AVG(un.purchase_price) as avg_purchase_price,
    AVG(dr.reward_amount) as avg_reward,
    AVG(un.purchase_price * dr.daily_rate) as expected_reward
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
WHERE dr.reward_date = CURRENT_DATE;

-- 5. 今日は何曜日かを確認
SELECT 
    CURRENT_DATE as today,
    EXTRACT(DOW FROM CURRENT_DATE) as day_of_week,
    CASE EXTRACT(DOW FROM CURRENT_DATE)
        WHEN 0 THEN '日曜日'
        WHEN 1 THEN '月曜日'
        WHEN 2 THEN '火曜日'
        WHEN 3 THEN '水曜日'
        WHEN 4 THEN '木曜日'
        WHEN 5 THEN '金曜日'
        WHEN 6 THEN '土曜日'
    END as day_name;
