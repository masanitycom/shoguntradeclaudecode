-- 計算ロジックを完全に修正

-- 1. 間違った報酬記録を全削除
DELETE FROM daily_rewards 
WHERE reward_date >= '2025-02-10'
AND user_nft_id IN (
    SELECT un.id 
    FROM user_nfts un 
    JOIN users u ON un.user_id = u.id 
    WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
);

-- 2. 正確な計算で報酬を再挿入
INSERT INTO daily_rewards (
    user_nft_id,
    user_id,
    nft_id,
    reward_date,
    reward_amount,
    daily_rate,
    investment_amount,
    week_start_date,
    calculation_date,
    calculation_details,
    is_claimed,
    created_at
)
SELECT 
    un.id as user_nft_id,
    un.user_id,
    un.nft_id,
    calc_dates.reward_date,
    -- 正確な報酬額計算（管理画面設定値を使用）
    n.price * CASE EXTRACT(DOW FROM calc_dates.reward_date)
        WHEN 1 THEN gwr.monday_rate
        WHEN 2 THEN gwr.tuesday_rate
        WHEN 3 THEN gwr.wednesday_rate
        WHEN 4 THEN gwr.thursday_rate
        WHEN 5 THEN gwr.friday_rate
        ELSE 0
    END as reward_amount,
    -- 正確な日利（管理画面設定値を使用）
    CASE EXTRACT(DOW FROM calc_dates.reward_date)
        WHEN 1 THEN gwr.monday_rate
        WHEN 2 THEN gwr.tuesday_rate
        WHEN 3 THEN gwr.wednesday_rate
        WHEN 4 THEN gwr.thursday_rate
        WHEN 5 THEN gwr.friday_rate
        ELSE 0
    END as daily_rate,
    n.price as investment_amount,
    gwr.week_start_date,
    CURRENT_DATE as calculation_date,
    jsonb_build_object(
        'nft_name', n.name,
        'nft_price', n.price,
        'group_name', drg.group_name,
        'day_of_week', EXTRACT(DOW FROM calc_dates.reward_date),
        'recalculated_correctly', true,
        'uses_admin_settings', true
    ) as calculation_details,
    false as is_claimed,
    NOW() as created_at
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
CROSS JOIN (
    -- 2/17週
    SELECT '2025-02-17'::date as reward_date, '2025-02-17'::date as week_start UNION
    SELECT '2025-02-18'::date, '2025-02-17'::date UNION
    SELECT '2025-02-19'::date, '2025-02-17'::date UNION
    SELECT '2025-02-20'::date, '2025-02-17'::date UNION
    SELECT '2025-02-21'::date, '2025-02-17'::date UNION
    -- 2/24週
    SELECT '2025-02-24'::date, '2025-02-24'::date UNION
    SELECT '2025-02-25'::date, '2025-02-24'::date UNION
    SELECT '2025-02-26'::date, '2025-02-24'::date UNION
    SELECT '2025-02-27'::date, '2025-02-24'::date UNION
    SELECT '2025-02-28'::date, '2025-02-24'::date UNION
    -- 3/3週
    SELECT '2025-03-03'::date, '2025-03-03'::date UNION
    SELECT '2025-03-04'::date, '2025-03-03'::date UNION
    SELECT '2025-03-05'::date, '2025-03-03'::date UNION
    SELECT '2025-03-06'::date, '2025-03-03'::date UNION
    SELECT '2025-03-07'::date, '2025-03-03'::date UNION
    -- 3/10週
    SELECT '2025-03-10'::date, '2025-03-10'::date UNION
    SELECT '2025-03-11'::date, '2025-03-10'::date UNION
    SELECT '2025-03-12'::date, '2025-03-10'::date UNION
    SELECT '2025-03-13'::date, '2025-03-10'::date UNION
    SELECT '2025-03-14'::date, '2025-03-10'::date
) calc_dates
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true
AND un.created_at::date <= calc_dates.reward_date  -- NFT取得日以降のみ
AND gwr.week_start_date = calc_dates.week_start
AND CASE EXTRACT(DOW FROM calc_dates.reward_date)
    WHEN 1 THEN gwr.monday_rate
    WHEN 2 THEN gwr.tuesday_rate
    WHEN 3 THEN gwr.wednesday_rate
    WHEN 4 THEN gwr.thursday_rate
    WHEN 5 THEN gwr.friday_rate
    ELSE 0
END > 0;  -- 0%の日は報酬なし

-- 3. user_nftsのtotal_earnedを正確に更新
UPDATE user_nfts 
SET total_earned = COALESCE((
    SELECT SUM(dr.reward_amount)
    FROM daily_rewards dr 
    WHERE dr.user_nft_id = user_nfts.id
), 0),
updated_at = NOW()
WHERE is_active = true;

-- 4. 修正結果の確認
SELECT 
    '✅ 修正後の正確な計算結果' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as NFT名,
    n.price as 投資額,
    un.total_earned as 累積報酬,
    CASE 
        WHEN n.price > 0 THEN 
            ROUND((un.total_earned / n.price * 100)::numeric, 6)
        ELSE 0 
    END as 収益率パーセント,
    COUNT(dr.id) as 報酬回数
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true
GROUP BY u.user_id, u.name, n.name, n.price, un.total_earned
ORDER BY u.user_id;

-- 5. 週別の詳細確認
SELECT 
    '📊 週別詳細確認' as info,
    u.user_id,
    u.name as ユーザー名,
    gwr.week_start_date as 週開始日,
    drg.group_name,
    gwr.weekly_rate * 100 as 設定週利パーセント,
    SUM(dr.reward_amount) as 実際の週間報酬,
    n.price * gwr.weekly_rate as 期待される週間報酬,
    CASE 
        WHEN ABS(SUM(dr.reward_amount) - n.price * gwr.weekly_rate) < 0.01 THEN '✅ 正確'
        ELSE '❌ 不正確'
    END as 計算正確性
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id 
    AND dr.reward_date BETWEEN gwr.week_start_date AND gwr.week_start_date + INTERVAL '4 days'
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'Sakura0326', 'Sakura0325', 'chococo12', 'naho1020')
AND un.is_active = true
AND gwr.week_start_date >= '2025-02-10'
GROUP BY u.user_id, u.name, gwr.week_start_date, drg.group_name, gwr.weekly_rate, n.price
ORDER BY u.user_id, gwr.week_start_date;
