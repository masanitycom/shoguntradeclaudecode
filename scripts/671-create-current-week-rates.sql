-- 現在の週の週利設定を作成

-- 1. 現在の週の開始日と終了日を計算
WITH current_week AS (
    SELECT 
        CURRENT_DATE - EXTRACT(DOW FROM CURRENT_DATE)::INTEGER + 1 as week_start,
        CURRENT_DATE - EXTRACT(DOW FROM CURRENT_DATE)::INTEGER + 7 as week_end,
        EXTRACT(week FROM CURRENT_DATE)::INTEGER as week_number
)
-- 2. 各グループの週利設定を作成
INSERT INTO group_weekly_rates (
    group_id,
    group_name,
    week_start_date,
    week_end_date,
    week_number,
    weekly_rate,
    monday_rate,
    tuesday_rate,
    wednesday_rate,
    thursday_rate,
    friday_rate,
    distribution_method,
    created_at,
    updated_at
)
SELECT 
    drg.id,
    drg.group_name,
    cw.week_start,
    cw.week_end,
    cw.week_number,
    0.026 as weekly_rate, -- 2.6%
    0.005 as monday_rate,    -- 0.5%
    0.006 as tuesday_rate,   -- 0.6%
    0.005 as wednesday_rate, -- 0.5%
    0.005 as thursday_rate,  -- 0.5%
    0.005 as friday_rate,    -- 0.5%
    'EMERGENCY_DEFAULT' as distribution_method,
    NOW(),
    NOW()
FROM daily_rate_groups drg
CROSS JOIN current_week cw
WHERE NOT EXISTS (
    SELECT 1 FROM group_weekly_rates gwr
    WHERE gwr.group_id = drg.id 
    AND gwr.week_start_date = cw.week_start
);

-- 3. 作成結果を確認
SELECT 
    gwr.group_name,
    gwr.week_start_date,
    gwr.week_end_date,
    gwr.weekly_rate,
    gwr.monday_rate,
    gwr.tuesday_rate,
    gwr.wednesday_rate,
    gwr.thursday_rate,
    gwr.friday_rate
FROM group_weekly_rates gwr
WHERE gwr.week_start_date = CURRENT_DATE - EXTRACT(DOW FROM CURRENT_DATE)::INTEGER + 1
ORDER BY gwr.group_name;
