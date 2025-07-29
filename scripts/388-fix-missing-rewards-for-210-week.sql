-- 2025-02-10週の報酬が計算されていない問題を修正

-- 1. 2025-02-10週の対象ユーザーで報酬が計算されていないケースを特定
WITH target_users AS (
    SELECT 
        un.id as user_nft_id,
        u.user_id,
        u.name,
        n.name as nft_name,
        n.price,
        n.daily_rate_limit,
        un.created_at as nft_created_at
    FROM user_nfts un
    JOIN users u ON un.user_id = u.id
    JOIN nfts n ON un.nft_id = n.id
    WHERE un.is_active = true
    AND un.created_at::date <= '2025-02-14'  -- 2/10週まで
    AND u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1')
),
missing_rewards AS (
    SELECT 
        tu.*,
        dr.reward_date
    FROM target_users tu
    CROSS JOIN (
        SELECT '2025-02-10'::date as reward_date UNION
        SELECT '2025-02-11'::date UNION
        SELECT '2025-02-12'::date UNION
        SELECT '2025-02-13'::date UNION
        SELECT '2025-02-14'::date
    ) dates
    LEFT JOIN daily_rewards dr ON tu.user_nft_id = dr.user_nft_id 
        AND dates.reward_date = dr.reward_date
    WHERE dr.reward_date IS NULL
)
SELECT 
    '❌ 計算されていない報酬' as info,
    mr.user_id,
    mr.name as ユーザー名,
    mr.nft_name as NFT名,
    mr.reward_date as 未計算日,
    CASE EXTRACT(DOW FROM mr.reward_date)
        WHEN 1 THEN '月曜'
        WHEN 2 THEN '火曜'
        WHEN 3 THEN '水曜'
        WHEN 4 THEN '木曜'
        WHEN 5 THEN '金曜'
    END as 曜日,
    mr.nft_created_at as NFT取得日
FROM missing_rewards mr
ORDER BY mr.user_id, mr.reward_date;

-- 2. 2025-02-10週の報酬を手動で計算・挿入
INSERT INTO daily_rewards (
    user_nft_id,
    reward_date,
    reward_amount,
    daily_rate,
    investment_amount,
    is_claimed,
    created_at
)
SELECT 
    un.id as user_nft_id,
    calc_date.reward_date,
    n.price * CASE EXTRACT(DOW FROM calc_date.reward_date)
        WHEN 1 THEN LEAST(COALESCE(gwr.monday_rate, 0), n.daily_rate_limit / 100.0)
        WHEN 2 THEN LEAST(COALESCE(gwr.tuesday_rate, 0), n.daily_rate_limit / 100.0)
        WHEN 3 THEN LEAST(COALESCE(gwr.wednesday_rate, 0), n.daily_rate_limit / 100.0)
        WHEN 4 THEN LEAST(COALESCE(gwr.thursday_rate, 0), n.daily_rate_limit / 100.0)
        WHEN 5 THEN LEAST(COALESCE(gwr.friday_rate, 0), n.daily_rate_limit / 100.0)
    END as reward_amount,
    CASE EXTRACT(DOW FROM calc_date.reward_date)
        WHEN 1 THEN LEAST(COALESCE(gwr.monday_rate, 0), n.daily_rate_limit / 100.0)
        WHEN 2 THEN LEAST(COALESCE(gwr.tuesday_rate, 0), n.daily_rate_limit / 100.0)
        WHEN 3 THEN LEAST(COALESCE(gwr.wednesday_rate, 0), n.daily_rate_limit / 100.0)
        WHEN 4 THEN LEAST(COALESCE(gwr.thursday_rate, 0), n.daily_rate_limit / 100.0)
        WHEN 5 THEN LEAST(COALESCE(gwr.friday_rate, 0), n.daily_rate_limit / 100.0)
    END as daily_rate,
    n.price as investment_amount,
    false as is_claimed,
    NOW() as created_at
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
CROSS JOIN (
    SELECT '2025-02-10'::date as reward_date UNION
    SELECT '2025-02-11'::date UNION
    SELECT '2025-02-12'::date UNION
    SELECT '2025-02-13'::date UNION
    SELECT '2025-02-14'::date
) calc_date
WHERE un.is_active = true
AND un.created_at::date <= calc_date.reward_date  -- NFT取得日以降のみ
AND gwr.week_start_date = '2025-02-10'
AND u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1')
AND NOT EXISTS (
    SELECT 1 FROM daily_rewards dr2 
    WHERE dr2.user_nft_id = un.id 
    AND dr2.reward_date = calc_date.reward_date
)
AND CASE EXTRACT(DOW FROM calc_date.reward_date)
    WHEN 1 THEN gwr.monday_rate
    WHEN 2 THEN gwr.tuesday_rate
    WHEN 3 THEN gwr.wednesday_rate
    WHEN 4 THEN gwr.thursday_rate
    WHEN 5 THEN gwr.friday_rate
END IS NOT NULL
AND CASE EXTRACT(DOW FROM calc_date.reward_date)
    WHEN 1 THEN gwr.monday_rate
    WHEN 2 THEN gwr.tuesday_rate
    WHEN 3 THEN gwr.wednesday_rate
    WHEN 4 THEN gwr.thursday_rate
    WHEN 5 THEN gwr.friday_rate
END > 0;

-- 3. user_nftsのtotal_earnedを更新
UPDATE user_nfts 
SET total_earned = (
    SELECT COALESCE(SUM(dr.reward_amount), 0)
    FROM daily_rewards dr
    WHERE dr.user_nft_id = user_nfts.id
),
updated_at = NOW()
WHERE id IN (
    SELECT un.id 
    FROM user_nfts un
    JOIN users u ON un.user_id = u.id
    WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1')
);

-- 4. 修正結果の確認
SELECT 
    '✅ 修正結果確認' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as NFT名,
    n.price as 投資額,
    un.total_earned as 累積報酬,
    (un.total_earned / n.price * 100) as 収益率パーセント,
    COUNT(dr.id) as 報酬回数
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1')
GROUP BY u.user_id, u.name, n.name, n.price, un.total_earned
ORDER BY u.user_id;
