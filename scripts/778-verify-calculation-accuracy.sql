-- 計算精度の検証

SELECT '=== 計算精度検証 ===' as section;

-- 各グループの期待値と実際の計算結果を比較
WITH expected_rates AS (
    SELECT 
        drg.group_name,
        gwr.monday_rate as expected_monday_rate,
        gwr.tuesday_rate as expected_tuesday_rate,
        gwr.wednesday_rate as expected_wednesday_rate,
        gwr.thursday_rate as expected_thursday_rate,
        gwr.friday_rate as expected_friday_rate
    FROM daily_rate_groups drg
    JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
    WHERE gwr.week_start_date = (
        SELECT MAX(week_start_date) FROM group_weekly_rates
    )
),
user_calculations AS (
    SELECT 
        u.email,
        n.name as nft_name,
        un.purchase_price,
        drg.group_name,
        gwr.monday_rate,
        un.purchase_price * gwr.monday_rate as calculated_monday_reward,
        LEAST(un.purchase_price * gwr.monday_rate, n.daily_rate_limit) as final_monday_reward
    FROM user_nfts un
    JOIN users u ON un.user_id = u.id
    JOIN nfts n ON un.nft_id = n.id
    JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
    JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
    WHERE u.is_admin = false
    AND gwr.week_start_date = (
        SELECT MAX(week_start_date) FROM group_weekly_rates
    )
)
SELECT 
    uc.email,
    uc.nft_name,
    uc.group_name,
    uc.purchase_price,
    ROUND(uc.monday_rate * 100, 3) as monday_rate_percent,
    ROUND(uc.calculated_monday_reward, 2) as calculated_reward,
    ROUND(uc.final_monday_reward, 2) as final_reward,
    CASE 
        WHEN uc.calculated_monday_reward = uc.final_monday_reward THEN '通常計算'
        ELSE '上限適用'
    END as calculation_type
FROM user_calculations uc
ORDER BY uc.group_name, uc.email;

-- グループ別集計
SELECT '=== グループ別集計 ===' as section;

SELECT 
    drg.group_name,
    COUNT(un.id) as nft_count,
    SUM(un.purchase_price) as total_investment,
    ROUND(AVG(gwr.monday_rate * 100), 3) as avg_monday_rate_percent,
    ROUND(SUM(LEAST(un.purchase_price * gwr.monday_rate, n.daily_rate_limit)), 2) as total_monday_rewards
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
WHERE u.is_admin = false
AND gwr.week_start_date = (
    SELECT MAX(week_start_date) FROM group_weekly_rates
)
GROUP BY drg.group_name, gwr.monday_rate
ORDER BY drg.group_name;
