-- 🚨 システム全体の週利・日利計算システムを緊急修正

-- 1. 現在のシステム全体の問題状況を把握
SELECT 
    '🚨 システム全体の問題確認' as info,
    COUNT(DISTINCT u.id) as 総ユーザー数,
    COUNT(DISTINCT un.id) as 総NFT投資数,
    SUM(un.current_investment) as 総投資額,
    SUM(un.total_earned) as 現在の総収益,
    ROUND(AVG(un.total_earned / un.current_investment * 100)::numeric, 4) as 平均収益率パーセント,
    '本来は約11.12%あるべき' as 期待値
FROM users u
JOIN user_nfts un ON u.id = un.user_id
WHERE un.is_active = true AND un.current_investment > 0;

-- 2. 管理画面設定値と実際の計算の乖離を確認
SELECT 
    '📋 管理画面設定vs実際の乖離' as info,
    gwr.week_start_date,
    drg.group_name,
    gwr.weekly_rate * 100 as 設定週利パーセント,
    (gwr.monday_rate + gwr.tuesday_rate + gwr.wednesday_rate + gwr.thursday_rate + gwr.friday_rate) * 100 as 実際の週利合計パーセント,
    COUNT(dr.id) as この週の報酬計算数,
    AVG(dr.daily_rate) * 100 as 実際の平均日利パーセント
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
LEFT JOIN daily_rewards dr ON dr.week_start_date = gwr.week_start_date
WHERE gwr.week_start_date >= '2025-02-10'
GROUP BY gwr.week_start_date, drg.group_name, gwr.weekly_rate, gwr.monday_rate, gwr.tuesday_rate, gwr.wednesday_rate, gwr.thursday_rate, gwr.friday_rate
ORDER BY gwr.week_start_date;

-- 3. 全ユーザーの現在の報酬状況を確認
SELECT 
    '💰 全ユーザー報酬状況' as info,
    COUNT(DISTINCT dr.user_id) as 報酬を受けたユーザー数,
    COUNT(dr.id) as 総報酬回数,
    SUM(dr.reward_amount) as 総報酬額,
    MIN(dr.reward_date) as 最初の報酬日,
    MAX(dr.reward_date) as 最後の報酬日,
    COUNT(DISTINCT dr.week_start_date) as 計算された週数
FROM daily_rewards dr
WHERE dr.reward_date >= '2025-02-10';

-- 4. 🚨 緊急修正：全ての間違った報酬を削除
DELETE FROM daily_rewards WHERE reward_date >= '2025-02-10';

-- 5. 🔧 正しい週利計算システムを構築
-- まず、正しい週利配分を確認
SELECT 
    '🔧 正しい週利配分確認' as info,
    week_start_date,
    weekly_rate * 100 as 週利パーセント,
    monday_rate * 100 as 月曜パーセント,
    tuesday_rate * 100 as 火曜パーセント,
    wednesday_rate * 100 as 水曜パーセント,
    thursday_rate * 100 as 木曜パーセント,
    friday_rate * 100 as 金曜パーセント
FROM group_weekly_rates 
WHERE week_start_date >= '2025-02-10' 
AND group_id = (SELECT id FROM daily_rate_groups WHERE group_name = 'group_100' LIMIT 1)
ORDER BY week_start_date;

-- 6. 🎯 全ユーザーに正しい報酬を一括適用
-- 2/10週（3.12%）- 全ユーザー
INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    dates.reward_date,
    un.current_investment * dates.daily_rate,
    dates.daily_rate,
    un.current_investment,
    '2025-02-10'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
CROSS JOIN (
    SELECT '2025-02-10'::date as reward_date, 0.00624::numeric as daily_rate UNION
    SELECT '2025-02-11'::date, 0.00624::numeric UNION
    SELECT '2025-02-12'::date, 0.00624::numeric UNION
    SELECT '2025-02-13'::date, 0.00624::numeric UNION
    SELECT '2025-02-14'::date, 0.00624::numeric
) dates
WHERE un.is_active = true 
AND un.current_investment > 0
AND un.operation_start_date <= '2025-02-10';

-- 2/17週（3.56%）- 全ユーザー
INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    dates.reward_date,
    un.current_investment * dates.daily_rate,
    dates.daily_rate,
    un.current_investment,
    '2025-02-17'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
CROSS JOIN (
    SELECT '2025-02-17'::date as reward_date, 0.00712::numeric as daily_rate UNION
    SELECT '2025-02-18'::date, 0.00712::numeric UNION
    SELECT '2025-02-19'::date, 0.00712::numeric UNION
    SELECT '2025-02-20'::date, 0.00712::numeric UNION
    SELECT '2025-02-21'::date, 0.00712::numeric
) dates
WHERE un.is_active = true 
AND un.current_investment > 0
AND un.operation_start_date <= '2025-02-17';

-- 2/24週（2.50%）- 全ユーザー
INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    dates.reward_date,
    un.current_investment * dates.daily_rate,
    dates.daily_rate,
    un.current_investment,
    '2025-02-24'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
CROSS JOIN (
    SELECT '2025-02-24'::date as reward_date, 0.005::numeric as daily_rate UNION
    SELECT '2025-02-25'::date, 0.005::numeric UNION
    SELECT '2025-02-26'::date, 0.005::numeric UNION
    SELECT '2025-02-27'::date, 0.005::numeric UNION
    SELECT '2025-02-28'::date, 0.005::numeric
) dates
WHERE un.is_active = true 
AND un.current_investment > 0
AND un.operation_start_date <= '2025-02-24';

-- 3/3週（0.38%）- 全ユーザー
INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    dates.reward_date,
    un.current_investment * dates.daily_rate,
    dates.daily_rate,
    un.current_investment,
    '2025-03-03'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
CROSS JOIN (
    SELECT '2025-03-03'::date as reward_date, 0.00076::numeric as daily_rate UNION
    SELECT '2025-03-04'::date, 0.00076::numeric UNION
    SELECT '2025-03-05'::date, 0.00076::numeric UNION
    SELECT '2025-03-06'::date, 0.00076::numeric UNION
    SELECT '2025-03-07'::date, 0.00076::numeric
) dates
WHERE un.is_active = true 
AND un.current_investment > 0
AND un.operation_start_date <= '2025-03-03';

-- 3/10週（1.58%）- 全ユーザー
INSERT INTO daily_rewards (
    user_nft_id, user_id, nft_id, reward_date, reward_amount, daily_rate, 
    investment_amount, week_start_date, calculation_date, is_claimed, created_at
)
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    dates.reward_date,
    un.current_investment * dates.daily_rate,
    dates.daily_rate,
    un.current_investment,
    '2025-03-10'::date,
    CURRENT_DATE,
    false,
    NOW()
FROM user_nfts un
CROSS JOIN (
    SELECT '2025-03-10'::date as reward_date, 0.00316::numeric as daily_rate UNION
    SELECT '2025-03-11'::date, 0.00316::numeric UNION
    SELECT '2025-03-12'::date, 0.00316::numeric UNION
    SELECT '2025-03-13'::date, 0.00316::numeric UNION
    SELECT '2025-03-14'::date, 0.00316::numeric
) dates
WHERE un.is_active = true 
AND un.current_investment > 0
AND un.operation_start_date <= '2025-03-10';

-- 7. 🔄 全ユーザーのtotal_earnedを正しく更新
UPDATE user_nfts 
SET total_earned = COALESCE((
    SELECT SUM(dr.reward_amount)
    FROM daily_rewards dr 
    WHERE dr.user_nft_id = user_nfts.id
), 0),
updated_at = NOW()
WHERE is_active = true;

-- 8. ✅ システム全体の修正結果を確認
SELECT 
    '✅ システム全体修正結果' as info,
    COUNT(DISTINCT u.id) as 修正対象ユーザー数,
    COUNT(DISTINCT un.id) as 修正対象NFT数,
    SUM(un.current_investment) as 総投資額,
    SUM(un.total_earned) as 修正後総収益,
    ROUND(AVG(un.total_earned / un.current_investment * 100)::numeric, 4) as 修正後平均収益率パーセント,
    COUNT(dr.id) as 総報酬計算数
FROM users u
JOIN user_nfts un ON u.id = un.user_id
LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id
WHERE un.is_active = true AND un.current_investment > 0;

-- 9. 📊 投資額別の修正結果詳細
SELECT 
    '📊 投資額別修正結果' as info,
    un.current_investment as 投資額,
    COUNT(*) as ユーザー数,
    AVG(un.total_earned) as 平均収益,
    ROUND(AVG(un.total_earned / un.current_investment * 100)::numeric, 4) as 平均収益率パーセント
FROM user_nfts un
WHERE un.is_active = true AND un.current_investment > 0
GROUP BY un.current_investment
ORDER BY un.current_investment;

-- 10. 🎯 週別報酬サマリー
SELECT 
    '🎯 週別報酬サマリー' as info,
    dr.week_start_date as 週開始日,
    COUNT(DISTINCT dr.user_id) as 対象ユーザー数,
    COUNT(dr.id) as 報酬計算数,
    SUM(dr.reward_amount) as 週間総報酬,
    AVG(dr.daily_rate) * 100 as 平均日利パーセント
FROM daily_rewards dr
WHERE dr.reward_date >= '2025-02-10'
GROUP BY dr.week_start_date
ORDER BY dr.week_start_date;
