-- 🧪 修正された計算システムのテスト

-- 1. 月曜日（2025-07-07）でテスト実行
SELECT '=== 月曜日計算テスト ===' as section;

SELECT calculate_daily_rewards_emergency('2025-07-07'::DATE) as monday_test_result;

-- 2. 計算結果の詳細確認
SELECT '=== 計算結果詳細確認 ===' as section;

SELECT 
    dr.reward_date,
    u.email,
    u.name,
    n.name as nft_name,
    un.purchase_price,
    n.daily_rate_limit,
    drg.group_name,
    dr.reward_amount,
    ROUND((dr.reward_amount / un.purchase_price * 100)::numeric, 4) as actual_rate_percent
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
WHERE dr.reward_date = '2025-07-07'
ORDER BY u.email, n.name;

-- 3. グループ別集計
SELECT '=== グループ別集計 ===' as section;

SELECT 
    drg.group_name,
    COUNT(*) as nft_count,
    SUM(un.purchase_price) as total_investment,
    SUM(dr.reward_amount) as total_rewards,
    ROUND(AVG(dr.reward_amount / un.purchase_price * 100)::numeric, 4) as avg_rate_percent
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
WHERE dr.reward_date = '2025-07-07'
GROUP BY drg.id, drg.group_name
ORDER BY drg.group_name;

-- 4. 期待値との比較
SELECT '=== 期待値との比較 ===' as section;

WITH expected_rates AS (
    SELECT 
        '0.5%グループ' as group_name,
        0.003 as expected_daily_rate,
        0.3 as expected_percent
    UNION ALL
    SELECT '1.0%グループ', 0.004, 0.4
    UNION ALL
    SELECT '1.25%グループ', 0.0046, 0.46
    UNION ALL
    SELECT '1.5%グループ', 0.0052, 0.52
    UNION ALL
    SELECT '1.75%グループ', 0.0058, 0.58
    UNION ALL
    SELECT '2.0%グループ', 0.0064, 0.64
),
actual_results AS (
    SELECT 
        drg.group_name,
        AVG(dr.reward_amount / un.purchase_price) as actual_daily_rate,
        ROUND(AVG(dr.reward_amount / un.purchase_price * 100)::numeric, 4) as actual_percent
    FROM daily_rewards dr
    JOIN user_nfts un ON dr.user_nft_id = un.id
    JOIN nfts n ON un.nft_id = n.id
    JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
    WHERE dr.reward_date = '2025-07-07'
    GROUP BY drg.group_name
)
SELECT 
    er.group_name,
    er.expected_percent as expected_rate_percent,
    ar.actual_percent as actual_rate_percent,
    CASE 
        WHEN ABS(er.expected_percent - ar.actual_percent) < 0.01 THEN '✅ 一致'
        ELSE '❌ 不一致'
    END as comparison_result
FROM expected_rates er
LEFT JOIN actual_results ar ON er.group_name = ar.group_name
ORDER BY er.group_name;

-- 5. システム全体の健全性チェック
SELECT '=== システム健全性チェック ===' as section;

SELECT 
    'NFTグループ設定' as check_item,
    COUNT(*) as total_nfts,
    COUNT(daily_rate_group_id) as nfts_with_group,
    CASE 
        WHEN COUNT(*) = COUNT(daily_rate_group_id) THEN '✅ 全NFTにグループ設定済み'
        ELSE format('❌ %s個のNFTにグループ未設定', COUNT(*) - COUNT(daily_rate_group_id))
    END as status
FROM nfts
UNION ALL
SELECT 
    '今週の週利設定',
    COUNT(DISTINCT drg.id),
    COUNT(DISTINCT gwr.group_id),
    CASE 
        WHEN COUNT(DISTINCT drg.id) = COUNT(DISTINCT gwr.group_id) THEN '✅ 全グループに今週の設定あり'
        ELSE format('❌ %s個のグループに今週の設定なし', COUNT(DISTINCT drg.id) - COUNT(DISTINCT gwr.group_id))
    END
FROM daily_rate_groups drg
LEFT JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
    AND CURRENT_DATE >= gwr.week_start_date
    AND CURRENT_DATE <= gwr.week_end_date;
