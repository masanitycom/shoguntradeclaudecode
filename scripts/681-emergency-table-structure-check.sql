-- テーブル構造の緊急確認

-- 1. group_weekly_ratesテーブルの構造を確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates'
ORDER BY ordinal_position;

-- 2. daily_rate_groupsテーブルの構造を確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'daily_rate_groups'
ORDER BY ordinal_position;

-- 3. 既存データの確認
SELECT 'group_weekly_rates data:' as info;
SELECT * FROM group_weekly_rates LIMIT 5;

SELECT 'daily_rate_groups data:' as info;
SELECT * FROM daily_rate_groups LIMIT 10;

-- 4. 制約の確認
SELECT 
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name IN ('group_weekly_rates', 'daily_rate_groups');
