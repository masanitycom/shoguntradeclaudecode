-- 計算結果の詳細検証

SELECT '=== システム状態確認 ===' as section;

-- 基本的なシステム状態
SELECT 
    'Users (non-admin)' as item,
    COUNT(*) as count
FROM users 
WHERE is_admin = false

UNION ALL

SELECT 
    'NFTs total' as item,
    COUNT(*) as count
FROM nfts

UNION ALL

SELECT 
    'User NFTs' as item,
    COUNT(*) as count
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE u.is_admin = false

UNION ALL

SELECT 
    'Daily Rate Groups' as item,
    COUNT(*) as count
FROM daily_rate_groups

UNION ALL

SELECT 
    'Weekly Rates (current)' as item,
    COUNT(*) as count
FROM group_weekly_rates
WHERE week_start_date <= CURRENT_DATE 
AND week_end_date >= CURRENT_DATE;

SELECT '=== グループ別週利設定状況 ===' as section;

-- 現在の週利設定を詳細表示
SELECT 
    drg.group_name,
    gwr.week_start_date,
    gwr.week_end_date,
    CONCAT(gwr.monday_rate, '%') as monday,
    CONCAT(gwr.tuesday_rate, '%') as tuesday,
    CONCAT(gwr.wednesday_rate, '%') as wednesday,
    CONCAT(gwr.thursday_rate, '%') as thursday,
    CONCAT(gwr.friday_rate, '%') as friday
FROM daily_rate_groups drg
LEFT JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
WHERE gwr.week_start_date <= CURRENT_DATE 
AND gwr.week_end_date >= CURRENT_DATE
ORDER BY drg.group_name;

SELECT '=== NFT別期待報酬計算 ===' as section;

-- 各NFTの期待報酬を詳細計算
WITH nft_calculations AS (
    SELECT 
        u.email,
        n.name as nft_name,
        un.purchase_price,
        n.daily_rate_limit,
        drg.group_name,
        CASE EXTRACT(DOW FROM CURRENT_DATE)
            WHEN 1 THEN gwr.monday_rate
            WHEN 2 THEN gwr.tuesday_rate
            WHEN 3 THEN gwr.wednesday_rate
            WHEN 4 THEN gwr.thursday_rate
            WHEN 5 THEN gwr.friday_rate
            ELSE 0
        END as daily_rate,
        un.purchase_price * (CASE EXTRACT(DOW FROM CURRENT_DATE)
            WHEN 1 THEN gwr.monday_rate
            WHEN 2 THEN gwr.tuesday_rate
            WHEN 3 THEN gwr.wednesday_rate
            WHEN 4 THEN gwr.thursday_rate
            WHEN 5 THEN gwr.friday_rate
            ELSE 0
        END / 100.0) as rate_based_reward,
        un.purchase_price * (n.daily_rate_limit / 100.0) as limit_based_reward
    FROM users u
    JOIN user_nfts un ON u.id = un.user_id
    JOIN nfts n ON un.nft_id = n.id
    JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
    JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
    WHERE u.is_admin = false
    AND un.operation_start_date <= CURRENT_DATE
    AND CURRENT_DATE >= gwr.week_start_date
    AND CURRENT_DATE <= gwr.week_end_date
)
SELECT 
    email,
    nft_name,
    CONCAT('$', purchase_price) as investment,
    CONCAT(daily_rate_limit, '%') as rate_limit,
    CONCAT(daily_rate, '%') as today_rate,
    CONCAT('$', ROUND(rate_based_reward, 2)) as rate_reward,
    CONCAT('$', ROUND(limit_based_reward, 2)) as limit_reward,
    CONCAT('$', ROUND(LEAST(rate_based_reward, limit_based_reward), 2)) as final_reward,
    CASE 
        WHEN rate_based_reward <= limit_based_reward THEN 'Rate Limited'
        ELSE 'Cap Limited'
    END as limitation_type
FROM nft_calculations
ORDER BY email, nft_name;

SELECT '=== グループ別集計 ===' as section;

-- グループ別の報酬集計
WITH group_summary AS (
    SELECT 
        drg.group_name,
        COUNT(un.id) as nft_count,
        SUM(un.purchase_price) as total_investment,
        AVG(n.daily_rate_limit) as avg_rate_limit,
        CASE EXTRACT(DOW FROM CURRENT_DATE)
            WHEN 1 THEN gwr.monday_rate
            WHEN 2 THEN gwr.tuesday_rate
            WHEN 3 THEN gwr.wednesday_rate
            WHEN 4 THEN gwr.thursday_rate
            WHEN 5 THEN gwr.friday_rate
            ELSE 0
        END as today_rate,
        SUM(LEAST(
            un.purchase_price * (CASE EXTRACT(DOW FROM CURRENT_DATE)
                WHEN 1 THEN gwr.monday_rate
                WHEN 2 THEN gwr.tuesday_rate
                WHEN 3 THEN gwr.wednesday_rate
                WHEN 4 THEN gwr.thursday_rate
                WHEN 5 THEN gwr.friday_rate
                ELSE 0
            END / 100.0),
            un.purchase_price * (n.daily_rate_limit / 100.0)
        )) as total_expected_reward
    FROM users u
    JOIN user_nfts un ON u.id = un.user_id
    JOIN nfts n ON un.nft_id = n.id
    JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
    JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
    WHERE u.is_admin = false
    AND un.operation_start_date <= CURRENT_DATE
    AND CURRENT_DATE >= gwr.week_start_date
    AND CURRENT_DATE <= gwr.week_end_date
    GROUP BY drg.id, drg.group_name, gwr.monday_rate, gwr.tuesday_rate, 
             gwr.wednesday_rate, gwr.thursday_rate, gwr.friday_rate
)
SELECT 
    group_name,
    nft_count,
    CONCAT('$', ROUND(total_investment, 2)) as total_investment,
    CONCAT(ROUND(avg_rate_limit, 2), '%') as avg_rate_limit,
    CONCAT(today_rate, '%') as today_rate,
    CONCAT('$', ROUND(total_expected_reward, 2)) as expected_reward
FROM group_summary
ORDER BY group_name;

SELECT '=== 実際の計算実行と結果比較 ===' as section;

-- 実際の計算を実行して結果を表示
SELECT test_daily_calculation(CURRENT_DATE) as calculation_result;

SELECT 'Detailed calculation verification completed' as status;
