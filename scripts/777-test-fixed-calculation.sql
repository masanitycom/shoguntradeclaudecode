-- 修正された計算システムのテスト

-- 1. 修正後の状況確認
SELECT '=== 修正後状況確認 ===' as section;

-- NFTグループ設定確認
SELECT 
    n.name,
    drg.group_name,
    n.daily_rate_limit
FROM nfts n
JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
ORDER BY n.name;

-- 2. 今週の週利設定確認
SELECT '=== 今週の週利設定 ===' as section;

SELECT 
    drg.group_name,
    gwr.weekly_rate * 100 as weekly_rate_percent,
    gwr.monday_rate * 100 as monday_percent,
    gwr.tuesday_rate * 100 as tuesday_percent,
    gwr.wednesday_rate * 100 as wednesday_percent,
    gwr.thursday_rate * 100 as thursday_percent,
    gwr.friday_rate * 100 as friday_percent
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE CURRENT_DATE >= gwr.week_start_date 
AND CURRENT_DATE <= gwr.week_end_date
ORDER BY drg.group_name;

-- 3. 修正された計算関数をテスト実行
SELECT '=== 計算関数テスト実行 ===' as section;

SELECT * FROM calculate_daily_rewards_fixed(CURRENT_DATE);

-- 4. 計算結果確認
SELECT '=== 計算結果確認 ===' as section;

SELECT 
    u.username,
    n.name as nft_name,
    un.purchase_price,
    dr.reward_amount,
    ROUND((dr.reward_amount / un.purchase_price * 100)::numeric, 4) as actual_rate_percent,
    drg.group_name
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
WHERE dr.reward_date = CURRENT_DATE
ORDER BY u.username, n.name;

-- 5. 計算の妥当性チェック
SELECT '=== 計算妥当性チェック ===' as section;

WITH calculation_check AS (
    SELECT 
        u.username,
        n.name as nft_name,
        un.purchase_price,
        dr.reward_amount,
        drg.group_name,
        -- 期待される日利率
        CASE EXTRACT(DOW FROM CURRENT_DATE)
            WHEN 1 THEN gwr.monday_rate
            WHEN 2 THEN gwr.tuesday_rate
            WHEN 3 THEN gwr.wednesday_rate
            WHEN 4 THEN gwr.thursday_rate
            WHEN 5 THEN gwr.friday_rate
            ELSE 0
        END as expected_rate,
        -- 期待される報酬額
        LEAST(
            un.purchase_price * CASE EXTRACT(DOW FROM CURRENT_DATE)
                WHEN 1 THEN gwr.monday_rate
                WHEN 2 THEN gwr.tuesday_rate
                WHEN 3 THEN gwr.wednesday_rate
                WHEN 4 THEN gwr.thursday_rate
                WHEN 5 THEN gwr.friday_rate
                ELSE 0
            END,
            n.daily_rate_limit
        ) as expected_amount
    FROM daily_rewards dr
    JOIN user_nfts un ON dr.user_nft_id = un.id
    JOIN users u ON un.user_id = u.id
    JOIN nfts n ON un.nft_id = n.id
    JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
    JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
    WHERE dr.reward_date = CURRENT_DATE
    AND CURRENT_DATE >= gwr.week_start_date 
    AND CURRENT_DATE <= gwr.week_end_date
)
SELECT 
    username,
    nft_name,
    purchase_price,
    group_name,
    ROUND(expected_rate * 100, 4) as expected_rate_percent,
    expected_amount,
    reward_amount,
    CASE 
        WHEN ABS(reward_amount - expected_amount) < 0.01 THEN '✅ 正確'
        ELSE '❌ 不一致'
    END as calculation_status
FROM calculation_check
ORDER BY username, nft_name;
