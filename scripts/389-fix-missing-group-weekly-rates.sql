-- 1.5%、1.75%、2.0%グループの週利設定が0になっている問題を修正

-- 1. 現在の問題状況を確認
SELECT 
    '❌ 週利0%のグループ確認' as info,
    drg.group_name,
    drg.daily_rate_limit as 日利上限,
    gwr.weekly_rate as 週利設定,
    gwr.week_start_date as 週開始日
FROM daily_rate_groups drg
JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
WHERE gwr.week_start_date = '2025-02-10'
AND gwr.weekly_rate = 0
ORDER BY drg.daily_rate_limit;

-- 2. 影響を受けるユーザーを確認
SELECT 
    '👥 影響を受けるユーザー' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as NFT名,
    n.daily_rate_limit as 日利上限,
    drg.group_name,
    un.created_at as NFT取得日
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
WHERE gwr.week_start_date = '2025-02-10'
AND gwr.weekly_rate = 0
AND un.is_active = true
ORDER BY u.user_id;

-- 3. 1.5%、1.75%、2.0%グループに適切な週利を設定
-- 1.5%グループ: 週利1.8%
UPDATE group_weekly_rates 
SET 
    weekly_rate = 0.018,
    monday_rate = 0.0000,
    tuesday_rate = 0.0064,
    wednesday_rate = 0.0006,
    thursday_rate = 0.0000,
    friday_rate = 0.0110,
    updated_at = NOW()
WHERE week_start_date = '2025-02-10'
AND group_id = (SELECT id FROM daily_rate_groups WHERE daily_rate_limit = 0.015);

-- 1.75%グループ: 週利2.1%
UPDATE group_weekly_rates 
SET 
    weekly_rate = 0.021,
    monday_rate = 0.0000,
    tuesday_rate = 0.0075,
    wednesday_rate = 0.0007,
    thursday_rate = 0.0000,
    friday_rate = 0.0128,
    updated_at = NOW()
WHERE week_start_date = '2025-02-10'
AND group_id = (SELECT id FROM daily_rate_groups WHERE daily_rate_limit = 0.0175);

-- 2.0%グループ: 週利2.4%
UPDATE group_weekly_rates 
SET 
    weekly_rate = 0.024,
    monday_rate = 0.0000,
    tuesday_rate = 0.0086,
    wednesday_rate = 0.0008,
    thursday_rate = 0.0000,
    friday_rate = 0.0146,
    updated_at = NOW()
WHERE week_start_date = '2025-02-10'
AND group_id = (SELECT id FROM daily_rate_groups WHERE daily_rate_limit = 0.02);

-- 4. 更新後の設定を確認
SELECT 
    '✅ 更新後の週利設定' as info,
    drg.group_name,
    drg.daily_rate_limit as 日利上限,
    gwr.weekly_rate as 週利設定,
    gwr.monday_rate as 月曜,
    gwr.tuesday_rate as 火曜,
    gwr.wednesday_rate as 水曜,
    gwr.thursday_rate as 木曜,
    gwr.friday_rate as 金曜,
    gwr.week_start_date as 週開始日
FROM daily_rate_groups drg
JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
WHERE gwr.week_start_date = '2025-02-10'
ORDER BY drg.daily_rate_limit;
