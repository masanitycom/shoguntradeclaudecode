-- 日利計算の問題を修正

-- 1. 不足している週利設定を作成
INSERT INTO group_weekly_rates (
    week_start_date,
    group_name,
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
    '2025-02-10'::date as week_start_date,
    drg.group_name,
    0.026 as weekly_rate, -- 2.6%
    0.005 as monday_rate,  -- 0.5%
    0.006 as tuesday_rate, -- 0.6%
    0.005 as wednesday_rate, -- 0.5%
    0.005 as thursday_rate,  -- 0.5%
    0.005 as friday_rate,    -- 0.5%
    'manual' as distribution_method,
    NOW() as created_at,
    NOW() as updated_at
FROM daily_rate_groups drg
WHERE NOT EXISTS (
    SELECT 1 FROM group_weekly_rates gwr 
    WHERE gwr.week_start_date = '2025-02-10' 
    AND gwr.group_name = drg.group_name
);

-- 2. 2025-02-17週の設定も作成
INSERT INTO group_weekly_rates (
    week_start_date,
    group_name,
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
    '2025-02-17'::date as week_start_date,
    drg.group_name,
    0.026 as weekly_rate, -- 2.6%
    0.005 as monday_rate,  -- 0.5%
    0.006 as tuesday_rate, -- 0.6%
    0.005 as wednesday_rate, -- 0.5%
    0.005 as thursday_rate,  -- 0.5%
    0.005 as friday_rate,    -- 0.5%
    'manual' as distribution_method,
    NOW() as created_at,
    NOW() as updated_at
FROM daily_rate_groups drg
WHERE NOT EXISTS (
    SELECT 1 FROM group_weekly_rates gwr 
    WHERE gwr.week_start_date = '2025-02-17' 
    AND gwr.group_name = drg.group_name
);

-- 3. 作成された週利設定を確認
SELECT 
    '=== 作成された週利設定 ===' as section,
    week_start_date,
    group_name,
    (weekly_rate * 100)::numeric(5,2) as weekly_rate_percent,
    (monday_rate * 100)::numeric(5,2) as monday_percent,
    distribution_method
FROM group_weekly_rates
WHERE week_start_date IN ('2025-02-10', '2025-02-17')
ORDER BY week_start_date, group_name;

SELECT '✅ 週利設定修正完了' as status;
