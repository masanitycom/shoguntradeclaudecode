-- 週別詳細確認（管理画面設定値との一致確認）- 修正版

-- 週別報酬サマリー（GROUP BY修正版）
WITH weekly_summary AS (
    SELECT 
        u.user_id,
        u.name as ユーザー名,
        n.price as 投資額,
        dr.week_start_date as 週開始日,
        SUM(dr.reward_amount) as 実際の週間報酬,
        COUNT(dr.id) as 報酬日数
    FROM user_nfts un
    JOIN users u ON un.user_id = u.id
    JOIN nfts n ON un.nft_id = n.id
    JOIN daily_rewards dr ON un.id = dr.user_nft_id
    WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
    AND un.is_active = true
    AND dr.reward_date >= '2025-02-10'
    GROUP BY u.user_id, u.name, n.price, dr.week_start_date
),
expected_rates AS (
    SELECT 
        '2025-02-10'::date as 週開始日,
        3.1200 as 管理画面設定週利パーセント,
        0.0312 as 期待週利率
    UNION ALL
    SELECT 
        '2025-02-17'::date,
        3.5600,
        0.0356
    UNION ALL
    SELECT 
        '2025-02-24'::date,
        2.5000,
        0.025
    UNION ALL
    SELECT 
        '2025-03-03'::date,
        0.3800,
        0.0038
    UNION ALL
    SELECT 
        '2025-03-10'::date,
        1.5800,
        0.0158
)
SELECT 
    '📊 週別詳細確認（管理画面設定値との一致）' as info,
    ws.user_id,
    ws.ユーザー名,
    ws.週開始日,
    '1.0%グループ' as group_name,
    er.管理画面設定週利パーセント::text as 管理画面設定週利パーセント,
    ws.実際の週間報酬,
    ROUND((ws.投資額 * er.期待週利率)::numeric, 6) as 期待される週間報酬,
    CASE 
        WHEN ABS(ws.実際の週間報酬 - (ws.投資額 * er.期待週利率)) < 0.01 THEN '✅ 完全一致'
        ELSE '❌ 不一致'
    END as 管理画面設定値との一致性,
    ws.報酬日数
FROM weekly_summary ws
JOIN expected_rates er ON ws.週開始日 = er.週開始日
ORDER BY ws.user_id, ws.週開始日;

-- 全体サマリー
SELECT 
    '📈 全体サマリー' as info,
    COUNT(DISTINCT u.user_id) as 対象ユーザー数,
    COUNT(DISTINCT dr.reward_date) as 報酬日数,
    COUNT(*) as 総報酬レコード数,
    SUM(dr.reward_amount) as 総報酬額,
    AVG(dr.reward_amount) as 平均日利報酬,
    MIN(dr.reward_date) as 開始日,
    MAX(dr.reward_date) as 終了日
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN daily_rewards dr ON un.id = dr.user_nft_id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true
AND dr.reward_date >= '2025-02-10';
