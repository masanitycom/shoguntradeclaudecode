-- 3/10週までの設定状況と計算確認

-- 1. 現在設定されている週利の全期間確認
SELECT 
    '📅 設定済み週利期間の確認' as info,
    gwr.week_start_date as 週開始日,
    gwr.week_start_date + INTERVAL '4 days' as 週終了日,
    drg.group_name,
    gwr.weekly_rate as 週利設定,
    gwr.monday_rate as 月曜,
    gwr.tuesday_rate as 火曜,
    gwr.wednesday_rate as 水曜,
    gwr.thursday_rate as 木曜,
    gwr.friday_rate as 金曜,
    (gwr.monday_rate + gwr.tuesday_rate + gwr.wednesday_rate + gwr.thursday_rate + gwr.friday_rate) as 日利合計
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date >= '2025-02-10'
ORDER BY gwr.week_start_date, drg.group_name;

-- 2. ユーザーのNFT取得日と対象期間の詳細確認
SELECT 
    '🎯 ユーザー別対象期間の詳細' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as NFT名,
    n.price as 投資額,
    drg.group_name,
    un.created_at::date as NFT取得日,
    CASE 
        WHEN un.created_at::date <= '2025-02-17' THEN '✅ 2/17週から対象'
        WHEN un.created_at::date <= '2025-02-24' THEN '✅ 2/24週から対象'
        WHEN un.created_at::date <= '2025-03-03' THEN '✅ 3/3週から対象'
        WHEN un.created_at::date <= '2025-03-10' THEN '✅ 3/10週から対象'
        ELSE '❌ 3/10週後に取得'
    END as 対象開始週,
    -- 対象となる週の数を計算
    CASE 
        WHEN un.created_at::date > '2025-03-14' THEN 0
        WHEN un.created_at::date <= '2025-02-17' THEN 4  -- 2/17, 2/24, 3/3, 3/10
        WHEN un.created_at::date <= '2025-02-24' THEN 3  -- 2/24, 3/3, 3/10
        WHEN un.created_at::date <= '2025-03-03' THEN 2  -- 3/3, 3/10
        WHEN un.created_at::date <= '2025-03-10' THEN 1  -- 3/10のみ
        ELSE 0
    END as 対象週数
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'mst1', 'DD123588', 'Norinori0504', 'Sakura0326', 'Sakura0325', 'chococo12', 'H.yui', 'naho1020')
AND un.is_active = true
ORDER BY u.user_id;

-- 3. 実際に計算されるべき報酬の試算（全期間）
WITH weekly_periods AS (
    SELECT '2025-02-17'::date as week_start, '2025-02-21'::date as week_end, '2/17週' as week_name UNION
    SELECT '2025-02-24'::date, '2025-02-28'::date, '2/24週' UNION
    SELECT '2025-03-03'::date, '2025-03-07'::date, '3/3週' UNION
    SELECT '2025-03-10'::date, '2025-03-14'::date, '3/10週'
),
user_eligibility AS (
    SELECT 
        u.user_id,
        u.name,
        n.name as nft_name,
        n.price,
        drg.group_name,
        un.created_at::date as nft_date,
        wp.week_start,
        wp.week_name,
        CASE WHEN un.created_at::date <= wp.week_start THEN true ELSE false END as is_eligible
    FROM user_nfts un
    JOIN users u ON un.user_id = u.id
    JOIN nfts n ON un.nft_id = n.id
    JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
    CROSS JOIN weekly_periods wp
    WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'mst1', 'DD123588', 'Norinori0504', 'Sakura0326', 'Sakura0325', 'chococo12', 'H.yui', 'naho1020')
    AND un.is_active = true
)
SELECT 
    '💰 期間別報酬試算' as info,
    ue.user_id,
    ue.name as ユーザー名,
    ue.nft_name as NFT名,
    ue.price as 投資額,
    ue.group_name,
    ue.week_name as 対象週,
    ue.is_eligible as 対象可否,
    CASE WHEN ue.is_eligible THEN
        COALESCE(gwr.weekly_rate * ue.price, 0)
    ELSE 0 END as 週間報酬予想額
FROM user_eligibility ue
LEFT JOIN group_weekly_rates gwr ON ue.week_start = gwr.week_start_date
LEFT JOIN daily_rate_groups drg ON ue.group_name = drg.group_name AND gwr.group_id = drg.id
ORDER BY ue.user_id, ue.week_start;

-- 4. 現在の累積報酬計算状況
SELECT 
    '📊 現在の累積報酬状況' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as NFT名,
    un.current_investment as 投資額,
    un.total_earned as 累積報酬,
    CASE 
        WHEN un.current_investment > 0 THEN 
            ROUND((un.total_earned / un.current_investment * 100)::numeric, 4)
        ELSE 0 
    END as 収益率パーセント,
    COUNT(dr.id) as 報酬計算回数,
    MIN(dr.reward_date) as 最初の報酬日,
    MAX(dr.reward_date) as 最後の報酬日
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'mst1', 'DD123588', 'Norinori0504', 'Sakura0326', 'Sakura0325', 'chococo12', 'H.yui', 'naho1020')
AND un.is_active = true
GROUP BY u.user_id, u.name, n.name, un.current_investment, un.total_earned
ORDER BY u.user_id;

-- 5. 管理画面表示用の正確な計算
SELECT 
    '🎯 管理画面表示用正確な計算' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as NFT名,
    un.current_investment as 投資額,
    COALESCE(SUM(dr.reward_amount), 0) as 実際の累積報酬,
    un.total_earned as テーブル上の累積報酬,
    CASE 
        WHEN COALESCE(SUM(dr.reward_amount), 0) != un.total_earned THEN '❌ 不一致'
        ELSE '✅ 一致'
    END as 整合性チェック,
    CASE 
        WHEN un.current_investment > 0 THEN 
            ROUND((COALESCE(SUM(dr.reward_amount), 0) / un.current_investment * 100)::numeric, 8)
        ELSE 0 
    END as 正確な収益率パーセント
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'mst1', 'DD123588', 'Norinori0504', 'Sakura0326', 'Sakura0325', 'chococo12', 'H.yui', 'naho1020')
AND un.is_active = true
GROUP BY u.user_id, u.name, n.name, un.current_investment, un.total_earned
ORDER BY u.user_id;
