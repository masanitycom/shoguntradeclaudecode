-- 週利設定修正後、2025-02-10週の報酬を再計算

-- 1. 対象ユーザーの2025-02-10週報酬を計算・挿入
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
    calc_date.reward_date,
    n.price * CASE EXTRACT(DOW FROM calc_date.reward_date)
        WHEN 1 THEN LEAST(COALESCE(gwr.monday_rate, 0), n.daily_rate_limit / 100.0)
        WHEN 2 THEN LEAST(COALESCE(gwr.tuesday_rate, 0), n.daily_rate_limit / 100.0)
        WHEN 3 THEN LEAST(COALESCE(gwr.wednesday_rate, 0), n.daily_rate_limit / 100.0)
        WHEN 4 THEN LEAST(COALESCE(gwr.thursday_rate, 0), n.daily_rate_limit / 100.0)
        WHEN 5 THEN LEAST(COALESCE(gwr.friday_rate, 0), n.daily_rate_limit / 100.0)
        ELSE 0
    END as reward_amount,
    CASE EXTRACT(DOW FROM calc_date.reward_date)
        WHEN 1 THEN LEAST(COALESCE(gwr.monday_rate, 0), n.daily_rate_limit / 100.0)
        WHEN 2 THEN LEAST(COALESCE(gwr.tuesday_rate, 0), n.daily_rate_limit / 100.0)
        WHEN 3 THEN LEAST(COALESCE(gwr.wednesday_rate, 0), n.daily_rate_limit / 100.0)
        WHEN 4 THEN LEAST(COALESCE(gwr.thursday_rate, 0), n.daily_rate_limit / 100.0)
        WHEN 5 THEN LEAST(COALESCE(gwr.friday_rate, 0), n.daily_rate_limit / 100.0)
        ELSE 0
    END as daily_rate,
    n.price as investment_amount,
    '2025-02-10'::date as week_start_date,
    CURRENT_DATE as calculation_date,
    jsonb_build_object(
        'nft_name', n.name,
        'nft_price', n.price,
        'group_name', drg.group_name,
        'day_of_week', EXTRACT(DOW FROM calc_date.reward_date),
        'recalculated', true
    ) as calculation_details,
    false as is_claimed,
    NOW() as created_at
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
CROSS JOIN (
    SELECT '2025-02-10'::date as reward_date UNION  -- 月曜
    SELECT '2025-02-11'::date UNION                 -- 火曜
    SELECT '2025-02-12'::date UNION                 -- 水曜
    SELECT '2025-02-13'::date UNION                 -- 木曜
    SELECT '2025-02-14'::date                       -- 金曜
) calc_date
WHERE un.is_active = true
AND un.created_at::date <= calc_date.reward_date  -- NFT取得日以降のみ
AND gwr.week_start_date = '2025-02-10'
AND gwr.weekly_rate > 0  -- 週利が設定されているもののみ
AND NOT EXISTS (
    SELECT 1 FROM daily_rewards dr2 
    WHERE dr2.user_nft_id = un.id 
    AND dr2.reward_date = calc_date.reward_date
)
AND CASE EXTRACT(DOW FROM calc_date.reward_date)
    WHEN 1 THEN COALESCE(gwr.monday_rate, 0)
    WHEN 2 THEN COALESCE(gwr.tuesday_rate, 0)
    WHEN 3 THEN COALESCE(gwr.wednesday_rate, 0)
    WHEN 4 THEN COALESCE(gwr.thursday_rate, 0)
    WHEN 5 THEN COALESCE(gwr.friday_rate, 0)
    ELSE 0
END > 0;

-- 2. user_nftsのtotal_earnedを更新
UPDATE user_nfts 
SET 
    total_earned = (
        SELECT COALESCE(SUM(dr.reward_amount), 0)
        FROM daily_rewards dr
        WHERE dr.user_nft_id = user_nfts.id
    ),
    updated_at = NOW()
WHERE EXISTS (
    SELECT 1 FROM daily_rewards dr
    WHERE dr.user_nft_id = user_nfts.id
    AND dr.reward_date BETWEEN '2025-02-10' AND '2025-02-14'
    AND dr.created_at > NOW() - INTERVAL '1 minute'  -- 今回追加された報酬のみ
);

-- 3. 計算結果の確認
SELECT 
    '💰 2025-02-10週報酬計算結果' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as NFT名,
    n.price as 投資額,
    un.total_earned as 累積報酬,
    ROUND((un.total_earned / n.price * 100)::numeric, 4) as 収益率パーセント,
    COUNT(dr.id) as 報酬回数,
    drg.group_name
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1')
GROUP BY u.user_id, u.name, n.name, n.price, un.total_earned, drg.group_name
ORDER BY u.user_id;

-- 4. 詳細な報酬履歴を確認
SELECT 
    '📊 詳細報酬履歴' as info,
    u.user_id,
    u.name as ユーザー名,
    dr.reward_date as 報酬日,
    CASE EXTRACT(DOW FROM dr.reward_date)
        WHEN 1 THEN '月曜'
        WHEN 2 THEN '火曜'
        WHEN 3 THEN '水曜'
        WHEN 4 THEN '木曜'
        WHEN 5 THEN '金曜'
    END as 曜日,
    ROUND((dr.daily_rate * 100)::numeric, 4) as 日利パーセント,
    dr.reward_amount as 報酬額,
    dr.investment_amount as 投資額
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN users u ON un.user_id = u.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1')
AND dr.reward_date BETWEEN '2025-02-10' AND '2025-02-14'
ORDER BY u.user_id, dr.reward_date;
