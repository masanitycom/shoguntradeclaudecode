-- =====================================================================
-- OHTAKIYOユーザーの正しい計算（修正後）
-- =====================================================================

-- 1. OHTAKIYOユーザーの現在の状況を確認
SELECT 
    '👤 OHTAKIYOユーザー現状確認' as status,
    u.username,
    u.email,
    un.current_investment,
    un.total_rewards_received,
    un.is_active,
    n.name as nft_name,
    n.price as nft_price,
    n.daily_rate_limit,
    ROUND(n.daily_rate_limit * 100, 2) || '%' as daily_limit_percent,
    ROUND(un.total_rewards_received / un.current_investment * 100, 2) || '%' as progress_percent,
    (un.current_investment * 3) - un.total_rewards_received as remaining_to_300_percent
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
WHERE u.username = 'OHTAKIYO'
ORDER BY un.created_at;

-- 2. 今週の正しい週利配分を確認
SELECT 
    '📅 今週の正しい配分（0.5%上限グループ）' as status,
    drg.group_name,
    ROUND(drg.daily_rate_limit * 100, 2) || '%' as nft_limit,
    ROUND(gwr.weekly_rate * 100, 2) || '%' as actual_weekly,
    CASE WHEN gwr.monday_rate = 0 THEN '0%' 
         ELSE ROUND(gwr.monday_rate * 100, 2) || '%' END as monday,
    CASE WHEN gwr.tuesday_rate = 0 THEN '0%' 
         ELSE ROUND(gwr.tuesday_rate * 100, 2) || '%' END as tuesday,
    CASE WHEN gwr.wednesday_rate = 0 THEN '0%' 
         ELSE ROUND(gwr.wednesday_rate * 100, 2) || '%' END as wednesday,
    CASE WHEN gwr.thursday_rate = 0 THEN '0%' 
         ELSE ROUND(gwr.thursday_rate * 100, 2) || '%' END as thursday,
    CASE WHEN gwr.friday_rate = 0 THEN '0%' 
         ELSE ROUND(gwr.friday_rate * 100, 2) || '%' END as friday
FROM daily_rate_groups drg
JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
WHERE drg.daily_rate_limit = 0.005  -- 0.5%グループ
  AND gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)::date;

-- 3. OHTAKIYOの今日の計算例
WITH today_calculation AS (
    SELECT 
        u.username,
        un.current_investment,
        un.total_rewards_received,
        n.daily_rate_limit as nft_limit,
        CASE EXTRACT(dow FROM CURRENT_DATE)
            WHEN 1 THEN gwr.monday_rate    -- 月曜
            WHEN 2 THEN gwr.tuesday_rate   -- 火曜
            WHEN 3 THEN gwr.wednesday_rate -- 水曜
            WHEN 4 THEN gwr.thursday_rate  -- 木曜
            WHEN 5 THEN gwr.friday_rate    -- 金曜
            ELSE 0  -- 土日
        END as today_rate,
        EXTRACT(dow FROM CURRENT_DATE) as day_of_week
    FROM users u
    JOIN user_nfts un ON u.id = un.user_id
    JOIN nfts n ON un.nft_id = n.id
    JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
    JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
    WHERE u.username = 'OHTAKIYO'
      AND gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)::date
)
SELECT 
    '💰 OHTAKIYO 今日の計算' as status,
    username,
    '$' || current_investment as investment,
    '$' || ROUND(total_rewards_received, 2) as cumulative_rewards,
    CASE day_of_week
        WHEN 0 THEN '日曜日（計算なし）'
        WHEN 1 THEN '月曜日'
        WHEN 2 THEN '火曜日'
        WHEN 3 THEN '水曜日'
        WHEN 4 THEN '木曜日'
        WHEN 5 THEN '金曜日'
        WHEN 6 THEN '土曜日（計算なし）'
    END as today,
    ROUND(today_rate * 100, 2) || '%' as today_rate_percent,
    ROUND(nft_limit * 100, 2) || '%' as nft_limit_percent,
    CASE 
        WHEN day_of_week IN (0, 6) THEN '$0（土日は計算なし）'
        WHEN today_rate = 0 THEN '$0（今日は0%設定）'
        ELSE '$' || ROUND(current_investment * today_rate, 2)
    END as today_reward,
    CASE 
        WHEN day_of_week IN (0, 6) THEN '土日は計算なし'
        WHEN today_rate = 0 THEN '今日は0%の日'
        WHEN today_rate > nft_limit THEN 'NFT上限で制限適用'
        ELSE '正常計算'
    END as calculation_note
FROM today_calculation;

-- 4. OHTAKIYOの週間予想収益
WITH weekly_projection AS (
    SELECT 
        u.username,
        un.current_investment,
        un.total_rewards_received,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        (gwr.monday_rate + gwr.tuesday_rate + gwr.wednesday_rate + 
         gwr.thursday_rate + gwr.friday_rate) as total_weekly_rate
    FROM users u
    JOIN user_nfts un ON u.id = un.user_id
    JOIN nfts n ON un.nft_id = n.id
    JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
    JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
    WHERE u.username = 'OHTAKIYO'
      AND gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)::date
)
SELECT 
    '📊 OHTAKIYO 今週の予想' as status,
    username,
    '$' || current_investment as investment,
    '$' || ROUND(total_rewards_received, 2) as current_cumulative,
    ROUND(total_weekly_rate * 100, 2) || '%' as weekly_rate,
    '$' || ROUND(current_investment * total_weekly_rate, 2) as weekly_reward,
    '$' || ROUND(total_rewards_received + (current_investment * total_weekly_rate), 2) as projected_cumulative,
    '$' || ROUND((current_investment * 3) - (total_rewards_received + (current_investment * total_weekly_rate)), 2) as remaining_to_300
FROM weekly_projection;

-- 5. 過去の日利履歴（最新5件）
SELECT 
    '📈 OHTAKIYO 最近の日利履歴' as status,
    TO_CHAR(dr.reward_date, 'MM/DD (Day)') as date,
    '$' || ROUND(dr.reward_amount, 2) as reward,
    ROUND(dr.daily_rate * 100, 2) || '%' as rate_used,
    dr.calculation_method
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN users u ON un.user_id = u.id
WHERE u.username = 'OHTAKIYO'
ORDER BY dr.reward_date DESC
LIMIT 5;
