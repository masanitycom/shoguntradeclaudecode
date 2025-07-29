-- 実際の計算ロジックを詳細調査

-- 1. 管理画面で設定された実際の週利を確認
SELECT 
    '📊 実際に設定された週利詳細' as info,
    gwr.week_start_date as 週開始日,
    drg.group_name,
    gwr.weekly_rate * 100 as 週利パーセント,
    gwr.monday_rate * 100 as 月曜パーセント,
    gwr.tuesday_rate * 100 as 火曜パーセント,
    gwr.wednesday_rate * 100 as 水曜パーセント,
    gwr.thursday_rate * 100 as 木曜パーセント,
    gwr.friday_rate * 100 as 金曜パーセント,
    (gwr.monday_rate + gwr.tuesday_rate + gwr.wednesday_rate + gwr.thursday_rate + gwr.friday_rate) * 100 as 実際の週利合計パーセント,
    drg.daily_rate_limit * 100 as 日利上限パーセント
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date >= '2025-02-10'
ORDER BY gwr.week_start_date, drg.daily_rate_limit;

-- 2. 実際に記録された報酬の詳細分析
SELECT 
    '🔍 実際の報酬記録詳細' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as NFT名,
    n.price as 投資額,
    dr.reward_date as 報酬日,
    EXTRACT(DOW FROM dr.reward_date) as 曜日番号,
    CASE EXTRACT(DOW FROM dr.reward_date)
        WHEN 1 THEN '月曜'
        WHEN 2 THEN '火曜'
        WHEN 3 THEN '水曜'
        WHEN 4 THEN '木曜'
        WHEN 5 THEN '金曜'
    END as 曜日,
    dr.daily_rate * 100 as 適用された日利パーセント,
    dr.reward_amount as 報酬額,
    dr.investment_amount as 計算時投資額,
    -- 期待される報酬額を計算
    CASE EXTRACT(DOW FROM dr.reward_date)
        WHEN 1 THEN gwr.monday_rate * n.price
        WHEN 2 THEN gwr.tuesday_rate * n.price
        WHEN 3 THEN gwr.wednesday_rate * n.price
        WHEN 4 THEN gwr.thursday_rate * n.price
        WHEN 5 THEN gwr.friday_rate * n.price
    END as 期待される報酬額,
    -- 差異チェック
    CASE 
        WHEN ABS(dr.reward_amount - CASE EXTRACT(DOW FROM dr.reward_date)
            WHEN 1 THEN gwr.monday_rate * n.price
            WHEN 2 THEN gwr.tuesday_rate * n.price
            WHEN 3 THEN gwr.wednesday_rate * n.price
            WHEN 4 THEN gwr.thursday_rate * n.price
            WHEN 5 THEN gwr.friday_rate * n.price
        END) < 0.01 THEN '✅ 正確'
        ELSE '❌ 不正確'
    END as 計算正確性
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
JOIN group_weekly_rates gwr ON drg.id = gwr.group_id 
    AND DATE_TRUNC('week', dr.reward_date)::date + INTERVAL '1 day' = gwr.week_start_date
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
ORDER BY u.user_id, dr.reward_date;

-- 3. 上限で計算されているかチェック
SELECT 
    '⚠️ 上限計算チェック' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as NFT名,
    drg.group_name,
    n.daily_rate_limit * 100 as 日利上限パーセント,
    dr.daily_rate * 100 as 適用された日利パーセント,
    CASE 
        WHEN dr.daily_rate >= n.daily_rate_limit * 0.99 THEN '❌ 上限で計算されている'
        ELSE '✅ 設定値で計算されている'
    END as 計算方式判定,
    dr.reward_amount as 報酬額,
    n.price * n.daily_rate_limit as 上限での報酬額,
    dr.reward_date as 報酬日
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
ORDER BY u.user_id, dr.reward_date;

-- 4. 計算関数の問題を特定
SELECT 
    '🔧 現在使用されている計算関数の確認' as info,
    routine_name as 関数名,
    routine_definition as 関数定義の一部
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name LIKE '%calculate%'
AND routine_name LIKE '%reward%'
ORDER BY routine_name;

-- 5. 実際の週利設定と報酬の対応関係
WITH weekly_settings AS (
    SELECT 
        gwr.week_start_date,
        drg.group_name,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate
    FROM group_weekly_rates gwr
    JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    WHERE gwr.week_start_date >= '2025-02-10'
)
SELECT 
    '📈 週利設定と実際の報酬の対応' as info,
    u.user_id,
    u.name as ユーザー名,
    ws.week_start_date as 週開始日,
    ws.group_name,
    ws.weekly_rate * 100 as 設定週利パーセント,
    SUM(dr.reward_amount) as 実際の週間報酬合計,
    n.price * ws.weekly_rate as 期待される週間報酬,
    CASE 
        WHEN ABS(SUM(dr.reward_amount) - n.price * ws.weekly_rate) < 0.01 THEN '✅ 一致'
        ELSE '❌ 不一致'
    END as 週間報酬一致性
FROM weekly_settings ws
JOIN daily_rate_groups drg ON ws.group_name = drg.group_name
JOIN nfts n ON n.daily_rate_limit = drg.daily_rate_limit
JOIN user_nfts un ON un.nft_id = n.id
JOIN users u ON un.user_id = u.id
LEFT JOIN daily_rewards dr ON dr.user_nft_id = un.id 
    AND dr.reward_date BETWEEN ws.week_start_date AND ws.week_start_date + INTERVAL '4 days'
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true
GROUP BY u.user_id, u.name, ws.week_start_date, ws.group_name, ws.weekly_rate, n.price
ORDER BY u.user_id, ws.week_start_date;
