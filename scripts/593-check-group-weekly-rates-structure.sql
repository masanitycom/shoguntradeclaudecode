-- group_weekly_ratesテーブルの構造を確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates' 
ORDER BY ordinal_position;

-- 既存データの確認
SELECT COUNT(*) as total_records FROM group_weekly_rates;

-- daily_rate_groupsテーブルの確認
SELECT 
    id,
    group_name,
    daily_rate_limit
FROM daily_rate_groups 
ORDER BY daily_rate_limit;
