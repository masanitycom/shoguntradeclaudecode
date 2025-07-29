-- daily_rate_groupsテーブルの詳細確認

-- 1. daily_rate_groupsテーブル構造確認
SELECT 
    '📋 daily_rate_groupsテーブル構造' as section,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'daily_rate_groups' 
ORDER BY ordinal_position;

-- 2. 既存のdaily_rate_groups確認
SELECT 
    '📊 既存daily_rate_groups' as section,
    id,
    group_name,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    description,
    created_at
FROM daily_rate_groups
ORDER BY daily_rate_limit;

-- 3. 外部キー制約確認
SELECT 
    '🔗 外部キー制約確認' as section,
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conname LIKE '%group_weekly_rates%' 
   OR conname LIKE '%daily_rate_groups%';

-- 4. 現在のgroup_weekly_rates状況
SELECT 
    '📅 現在の週利設定状況' as section,
    COUNT(*) as total_settings,
    COUNT(DISTINCT group_id) as unique_groups,
    MIN(week_start_date) as earliest_week,
    MAX(week_start_date) as latest_week
FROM group_weekly_rates;

-- 5. 詳細な週利設定確認
SELECT 
    '🔍 詳細週利設定' as section,
    gwr.group_id,
    drg.group_name,
    drg.daily_rate_limit,
    gwr.weekly_rate,
    gwr.week_start_date,
    gwr.created_at
FROM group_weekly_rates gwr
LEFT JOIN daily_rate_groups drg ON gwr.group_id = drg.id
ORDER BY drg.daily_rate_limit;
