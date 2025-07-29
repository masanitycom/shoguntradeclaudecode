-- 確実に動作する週利設定の作成

-- 1. 既存の週利データをクリア
DELETE FROM group_weekly_rates;

-- 2. 現在の週の開始日を計算し、適切なgroup_idを取得して挿入
WITH current_week AS (
    SELECT 
        CURRENT_DATE - EXTRACT(DOW FROM CURRENT_DATE)::INTEGER + 1 as week_start,
        CURRENT_DATE - EXTRACT(DOW FROM CURRENT_DATE)::INTEGER + 7 as week_end
),
default_group AS (
    SELECT id as group_id FROM daily_rate_groups LIMIT 1
)
-- 3. 各グループの週利設定を直接挿入（必須カラムを含む）
INSERT INTO group_weekly_rates (
    id,
    week_start_date,
    weekly_rate,
    monday_rate,
    tuesday_rate,
    wednesday_rate,
    thursday_rate,
    friday_rate,
    group_id,
    group_name,
    week_end_date,
    distribution_method,
    created_at,
    updated_at
)
SELECT 
    gen_random_uuid(),
    cw.week_start,
    0.026,    -- 2.6%週利
    0.0052,   -- 月曜日 0.52%
    0.0065,   -- 火曜日 0.65%
    0.0052,   -- 水曜日 0.52%
    0.0052,   -- 木曜日 0.52%
    0.0039,   -- 金曜日 0.39%
    dg.group_id,
    '全グループ共通',
    cw.week_end,
    'EMERGENCY_FIX',
    NOW(),
    NOW()
FROM current_week cw, default_group dg;

-- 4. 作成結果を確認
SELECT 
    '✅ 週利設定作成完了' as status,
    week_start_date,
    week_end_date,
    weekly_rate * 100 as weekly_rate_percent,
    monday_rate * 100 as monday_percent,
    tuesday_rate * 100 as tuesday_percent,
    wednesday_rate * 100 as wednesday_percent,
    thursday_rate * 100 as thursday_percent,
    friday_rate * 100 as friday_percent,
    (monday_rate + tuesday_rate + wednesday_rate + thursday_rate + friday_rate) * 100 as total_daily_percent,
    group_name,
    distribution_method
FROM group_weekly_rates
WHERE week_start_date = CURRENT_DATE - EXTRACT(DOW FROM CURRENT_DATE)::INTEGER + 1;

-- 5. 全グループに対して同じ設定を複製
INSERT INTO group_weekly_rates (
    id,
    week_start_date,
    weekly_rate,
    monday_rate,
    tuesday_rate,
    wednesday_rate,
    thursday_rate,
    friday_rate,
    group_id,
    group_name,
    week_end_date,
    distribution_method,
    created_at,
    updated_at
)
SELECT 
    gen_random_uuid(),
    gwr.week_start_date,
    gwr.weekly_rate,
    gwr.monday_rate,
    gwr.tuesday_rate,
    gwr.wednesday_rate,
    gwr.thursday_rate,
    gwr.friday_rate,
    drg.id,
    drg.group_name,
    gwr.week_end_date,
    'EMERGENCY_FIX',
    NOW(),
    NOW()
FROM group_weekly_rates gwr
CROSS JOIN daily_rate_groups drg
WHERE NOT EXISTS (
    SELECT 1 FROM group_weekly_rates gwr2 
    WHERE gwr2.group_id = drg.id 
    AND gwr2.week_start_date = gwr.week_start_date
)
LIMIT 6; -- 6つのグループ分

-- 6. 最終確認
SELECT 
    '📊 全グループ設定確認' as section,
    COUNT(*) as total_settings,
    COUNT(DISTINCT group_id) as unique_groups,
    COUNT(DISTINCT week_start_date) as unique_weeks
FROM group_weekly_rates;

SELECT 
    drg.group_name,
    gwr.weekly_rate * 100 as weekly_percent,
    gwr.monday_rate * 100 as mon_percent,
    gwr.distribution_method
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = CURRENT_DATE - EXTRACT(DOW FROM CURRENT_DATE)::INTEGER + 1
ORDER BY drg.group_name;
