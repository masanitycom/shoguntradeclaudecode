-- 適切な週利設定を作成

-- 1. 現在の週利設定をクリア
DELETE FROM group_weekly_rates 
WHERE week_start_date = CURRENT_DATE - EXTRACT(DOW FROM CURRENT_DATE)::INTEGER + 1;

-- 2. 現在の週の開始日と終了日を計算
WITH current_week AS (
    SELECT 
        CURRENT_DATE - EXTRACT(DOW FROM CURRENT_DATE)::INTEGER + 1 as week_start,
        CURRENT_DATE - EXTRACT(DOW FROM CURRENT_DATE)::INTEGER + 7 as week_end
)
-- 3. 各グループの適切な週利設定を作成
INSERT INTO group_weekly_rates (
    group_id,
    group_name,
    week_start_date,
    week_end_date,
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
    CASE drg.group_name
        WHEN '0.5%グループ' THEN 0.015   -- 1.5%週利
        WHEN '1.0%グループ' THEN 0.020   -- 2.0%週利
        WHEN '1.25%グループ' THEN 0.023  -- 2.3%週利
        WHEN '1.5%グループ' THEN 0.026   -- 2.6%週利
        WHEN '1.75%グループ' THEN 0.029  -- 2.9%週利
        WHEN '2.0%グループ' THEN 0.032   -- 3.2%週利
        ELSE 0.026
    END as weekly_rate,
    -- 月曜日（20%）
    CASE drg.group_name
        WHEN '0.5%グループ' THEN 0.003   -- 0.3%
        WHEN '1.0%グループ' THEN 0.004   -- 0.4%
        WHEN '1.25%グループ' THEN 0.0046 -- 0.46%
        WHEN '1.5%グループ' THEN 0.0052  -- 0.52%
        WHEN '1.75%グループ' THEN 0.0058 -- 0.58%
        WHEN '2.0%グループ' THEN 0.0064  -- 0.64%
        ELSE 0.0052
    END as monday_rate,
    -- 火曜日（25%）
    CASE drg.group_name
        WHEN '0.5%グループ' THEN 0.00375 -- 0.375%
        WHEN '1.0%グループ' THEN 0.005   -- 0.5%
        WHEN '1.25%グループ' THEN 0.00575-- 0.575%
        WHEN '1.5%グループ' THEN 0.0065  -- 0.65%
        WHEN '1.75%グループ' THEN 0.00725-- 0.725%
        WHEN '2.0%グループ' THEN 0.008   -- 0.8%
        ELSE 0.0065
    END as tuesday_rate,
    -- 水曜日（20%）
    CASE drg.group_name
        WHEN '0.5%グループ' THEN 0.003   -- 0.3%
        WHEN '1.0%グループ' THEN 0.004   -- 0.4%
        WHEN '1.25%グループ' THEN 0.0046 -- 0.46%
        WHEN '1.5%グループ' THEN 0.0052  -- 0.52%
        WHEN '1.75%グループ' THEN 0.0058 -- 0.58%
        WHEN '2.0%グループ' THEN 0.0064  -- 0.64%
        ELSE 0.0052
    END as wednesday_rate,
    -- 木曜日（20%）
    CASE drg.group_name
        WHEN '0.5%グループ' THEN 0.003   -- 0.3%
        WHEN '1.0%グループ' THEN 0.004   -- 0.4%
        WHEN '1.25%グループ' THEN 0.0046 -- 0.46%
        WHEN '1.5%グループ' THEN 0.0052  -- 0.52%
        WHEN '1.75%グループ' THEN 0.0058 -- 0.58%
        WHEN '2.0%グループ' THEN 0.0064  -- 0.64%
        ELSE 0.0052
    END as thursday_rate,
    -- 金曜日（15%）
    CASE drg.group_name
        WHEN '0.5%グループ' THEN 0.00225 -- 0.225%
        WHEN '1.0%グループ' THEN 0.003   -- 0.3%
        WHEN '1.25%グループ' THEN 0.00345-- 0.345%
        WHEN '1.5%グループ' THEN 0.0039  -- 0.39%
        WHEN '1.75%グループ' THEN 0.00435-- 0.435%
        WHEN '2.0%グループ' THEN 0.0048  -- 0.48%
        ELSE 0.0039
    END as friday_rate,
    'MANUAL_CORRECTED' as distribution_method,
    NOW(),
    NOW()
FROM daily_rate_groups drg
CROSS JOIN current_week cw;

-- 4. 作成結果を確認
SELECT 
    gwr.group_name,
    gwr.week_start_date,
    gwr.weekly_rate * 100 as weekly_rate_percent,
    gwr.monday_rate * 100 as monday_percent,
    gwr.tuesday_rate * 100 as tuesday_percent,
    gwr.wednesday_rate * 100 as wednesday_percent,
    gwr.thursday_rate * 100 as thursday_percent,
    gwr.friday_rate * 100 as friday_percent,
    (gwr.monday_rate + gwr.tuesday_rate + gwr.wednesday_rate + gwr.thursday_rate + gwr.friday_rate) * 100 as total_daily_percent
FROM group_weekly_rates gwr
WHERE gwr.week_start_date = CURRENT_DATE - EXTRACT(DOW FROM CURRENT_DATE)::INTEGER + 1
ORDER BY gwr.group_name;
