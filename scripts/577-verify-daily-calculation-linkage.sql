-- 🔗 日利計算と週利設定の連動確認・修正
-- 週利設定が日利計算に正しく反映されているかチェック

-- 1. 現在の連動状況を詳細確認
SELECT 
    '🔍 連動状況詳細確認' as check_type,
    '今日の曜日: ' || EXTRACT(DOW FROM CURRENT_DATE) as day_info,
    '今週の開始日: ' || (CURRENT_DATE - (EXTRACT(DOW FROM CURRENT_DATE) - 1)) as week_start,
    '今日は平日: ' || (EXTRACT(DOW FROM CURRENT_DATE) BETWEEN 1 AND 5) as is_weekday;

-- 2. 今週の週利設定確認
WITH current_week AS (
    SELECT (CURRENT_DATE - (EXTRACT(DOW FROM CURRENT_DATE) - 1)) as week_start
)
SELECT 
    '📅 今週の週利設定' as check_type,
    drg.group_name,
    gwr.week_start_date,
    ROUND(gwr.weekly_rate * 100, 2) || '%' as weekly_rate,
    CASE EXTRACT(DOW FROM CURRENT_DATE)
        WHEN 1 THEN ROUND(gwr.monday_rate * 100, 3) || '%'
        WHEN 2 THEN ROUND(gwr.tuesday_rate * 100, 3) || '%'
        WHEN 3 THEN ROUND(gwr.wednesday_rate * 100, 3) || '%'
        WHEN 4 THEN ROUND(gwr.thursday_rate * 100, 3) || '%'
        WHEN 5 THEN ROUND(gwr.friday_rate * 100, 3) || '%'
        ELSE '0%'
    END as today_rate
FROM current_week cw
JOIN group_weekly_rates gwr ON gwr.week_start_date = cw.week_start
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
ORDER BY drg.daily_rate_limit;

-- 3. 今日の日利計算結果確認
SELECT 
    '💰 今日の日利計算結果' as check_type,
    COUNT(*) as calculation_count,
    COALESCE(SUM(reward_amount), 0) as total_rewards,
    ROUND(AVG(daily_rate_applied) * 100, 3) || '%' as avg_daily_rate
FROM daily_rewards 
WHERE reward_date = CURRENT_DATE;

-- 4. ユーザー別の今日の報酬詳細
SELECT 
    '👤 ユーザー別今日の報酬' as check_type,
    u.name,
    COUNT(dr.id) as reward_count,
    COALESCE(SUM(dr.reward_amount), 0) as total_reward,
    ROUND(AVG(dr.daily_rate_applied) * 100, 3) || '%' as avg_rate
FROM users u
LEFT JOIN daily_rewards dr ON u.id = dr.user_id AND dr.reward_date = CURRENT_DATE
WHERE u.is_admin = false
GROUP BY u.id, u.name
HAVING COUNT(dr.id) > 0
ORDER BY total_reward DESC
LIMIT 10;

-- 5. NFT別の今日の報酬確認
SELECT 
    '🎨 NFT別今日の報酬' as check_type,
    n.name,
    n.daily_rate_limit,
    COUNT(dr.id) as calculation_count,
    COALESCE(SUM(dr.reward_amount), 0) as total_rewards,
    ROUND(AVG(dr.daily_rate_applied) * 100, 3) || '%' as avg_applied_rate
FROM nfts n
LEFT JOIN daily_rewards dr ON n.id = dr.nft_id AND dr.reward_date = CURRENT_DATE
WHERE n.is_active = true
GROUP BY n.id, n.name, n.daily_rate_limit
HAVING COUNT(dr.id) > 0
ORDER BY n.daily_rate_limit, total_rewards DESC;

-- 6. 週利設定と日利計算の不整合チェック
WITH current_week AS (
    SELECT (CURRENT_DATE - (EXTRACT(DOW FROM CURRENT_DATE) - 1)) as week_start
),
expected_rates AS (
    SELECT 
        drg.daily_rate_limit,
        CASE EXTRACT(DOW FROM CURRENT_DATE)
            WHEN 1 THEN gwr.monday_rate
            WHEN 2 THEN gwr.tuesday_rate
            WHEN 3 THEN gwr.wednesday_rate
            WHEN 4 THEN gwr.thursday_rate
            WHEN 5 THEN gwr.friday_rate
            ELSE 0
        END as expected_rate
    FROM current_week cw
    JOIN group_weekly_rates gwr ON gwr.week_start_date = cw.week_start
    JOIN daily_rate_groups drg ON gwr.group_id = drg.id
),
actual_rates AS (
    SELECT 
        n.daily_rate_limit,
        AVG(dr.daily_rate_applied) as actual_rate
    FROM daily_rewards dr
    JOIN nfts n ON dr.nft_id = n.id
    WHERE dr.reward_date = CURRENT_DATE
    GROUP BY n.daily_rate_limit
)
SELECT 
    '⚠️ 不整合チェック' as check_type,
    er.daily_rate_limit,
    ROUND(er.expected_rate * 100, 3) || '%' as expected_rate,
    ROUND(COALESCE(ar.actual_rate, 0) * 100, 3) || '%' as actual_rate,
    CASE 
        WHEN ABS(er.expected_rate - COALESCE(ar.actual_rate, 0)) < 0.0001 THEN '✅ 一致'
        WHEN ar.actual_rate IS NULL THEN '❌ 計算なし'
        ELSE '⚠️ 不一致'
    END as status
FROM expected_rates er
LEFT JOIN actual_rates ar ON er.daily_rate_limit = ar.daily_rate_limit
ORDER BY er.daily_rate_limit;

-- 7. 今日の日利計算を強制再実行（連動テスト）
SELECT 
    '🔄 日利計算再実行' as action,
    * 
FROM calculate_daily_rewards_batch(CURRENT_DATE);

-- 8. 再実行後の結果確認
SELECT 
    '✅ 再実行後確認' as check_type,
    COUNT(*) as new_calculation_count,
    COALESCE(SUM(reward_amount), 0) as new_total_rewards
FROM daily_rewards 
WHERE reward_date = CURRENT_DATE;
