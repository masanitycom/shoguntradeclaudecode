-- 🚨 緊急計算診断 - 計算が合わない原因を特定

-- 1. 現在のシステム状況を詳細確認
SELECT '=== システム状況確認 ===' as section;

-- ユーザーNFT状況
SELECT 
    u.username,
    u.email,
    COUNT(un.id) as nft_count,
    SUM(un.purchase_price) as total_investment,
    STRING_AGG(DISTINCT n.name, ', ') as nft_names,
    STRING_AGG(DISTINCT drg.group_name, ', ') as nft_groups
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id
LEFT JOIN nfts n ON un.nft_id = n.id
LEFT JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
WHERE u.is_admin = false
GROUP BY u.id, u.username, u.email
ORDER BY u.username;

-- 2. NFTとグループの対応確認
SELECT '=== NFTグループ対応確認 ===' as section;

SELECT 
    n.id,
    n.name,
    n.price,
    n.daily_rate_limit,
    drg.group_name,
    drg.id as group_id
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
ORDER BY n.id;

-- 3. 現在の週利設定確認
SELECT '=== 現在の週利設定 ===' as section;

SELECT 
    gwr.week_start_date,
    gwr.week_end_date,
    drg.group_name,
    gwr.weekly_rate,
    gwr.monday_rate,
    gwr.tuesday_rate,
    gwr.wednesday_rate,
    gwr.thursday_rate,
    gwr.friday_rate
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
ORDER BY gwr.week_start_date DESC, drg.group_name;

-- 4. 最新の日利報酬確認
SELECT '=== 最新日利報酬確認 ===' as section;

SELECT 
    dr.reward_date,
    u.username,
    n.name as nft_name,
    un.purchase_price,
    dr.reward_amount,
    ROUND((dr.reward_amount / un.purchase_price * 100)::numeric, 4) as actual_rate_percent
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE dr.reward_date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY dr.reward_date DESC, u.username
LIMIT 20;

-- 5. 今日の計算対象データ確認
SELECT '=== 今日の計算対象確認 ===' as section;

WITH today_calculation AS (
    SELECT 
        un.id as user_nft_id,
        u.username,
        n.name as nft_name,
        un.purchase_price,
        n.daily_rate_limit,
        drg.group_name,
        -- 今日の曜日に対応する週利を取得
        CASE EXTRACT(DOW FROM CURRENT_DATE)
            WHEN 1 THEN gwr.monday_rate
            WHEN 2 THEN gwr.tuesday_rate
            WHEN 3 THEN gwr.wednesday_rate
            WHEN 4 THEN gwr.thursday_rate
            WHEN 5 THEN gwr.friday_rate
            ELSE 0
        END as today_rate,
        -- 計算される報酬額
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
        ) as calculated_reward
    FROM user_nfts un
    JOIN users u ON un.user_id = u.id
    JOIN nfts n ON un.nft_id = n.id
    JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
    LEFT JOIN group_weekly_rates gwr ON drg.id = gwr.group_id 
        AND CURRENT_DATE >= gwr.week_start_date 
        AND CURRENT_DATE <= gwr.week_end_date
    WHERE u.is_admin = false
    AND un.operation_start_date <= CURRENT_DATE
)
SELECT 
    username,
    nft_name,
    purchase_price,
    daily_rate_limit,
    group_name,
    today_rate,
    ROUND(today_rate * 100, 4) as today_rate_percent,
    calculated_reward,
    CASE 
        WHEN today_rate = 0 THEN '週利設定なし'
        WHEN calculated_reward = 0 THEN '計算結果ゼロ'
        WHEN calculated_reward = daily_rate_limit THEN '上限適用'
        ELSE '通常計算'
    END as calculation_status
FROM today_calculation
ORDER BY username, nft_name;

-- 6. 週利設定の欠損確認
SELECT '=== 週利設定欠損確認 ===' as section;

SELECT 
    drg.group_name,
    COUNT(DISTINCT gwr.week_start_date) as weeks_with_rates,
    MIN(gwr.week_start_date) as first_week,
    MAX(gwr.week_start_date) as last_week
FROM daily_rate_groups drg
LEFT JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
GROUP BY drg.id, drg.group_name
ORDER BY drg.group_name;

-- 7. 計算関数の動作確認
SELECT '=== 計算関数動作確認 ===' as section;

-- 今日の日付で計算関数を実行してみる
SELECT 
    'calculate_daily_rewards実行結果' as test_name,
    CURRENT_DATE as target_date,
    EXTRACT(DOW FROM CURRENT_DATE) as day_of_week,
    CASE EXTRACT(DOW FROM CURRENT_DATE)
        WHEN 0 THEN '日曜日（計算対象外）'
        WHEN 1 THEN '月曜日'
        WHEN 2 THEN '火曜日'
        WHEN 3 THEN '水曜日'
        WHEN 4 THEN '木曜日'
        WHEN 5 THEN '金曜日'
        WHEN 6 THEN '土曜日（計算対象外）'
    END as day_name;
