-- 緊急データ復旧 - テーブル構造確認と手動設定データ調査

-- 1. まず現在のテーブル構造を確認
SELECT 'Checking table structures...' as status;

-- group_weekly_rates テーブル構造確認
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates' 
ORDER BY ordinal_position;

-- group_weekly_rates_backup テーブル構造確認
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates_backup' 
ORDER BY ordinal_position;

-- 2. 現在のgroup_weekly_ratesの内容確認
SELECT 
    'Current group_weekly_rates data:' as info,
    COUNT(*) as total_records
FROM group_weekly_rates;

-- 3. バックアップテーブルの内容確認
SELECT 
    'Backup table data:' as info,
    COUNT(*) as total_backup_records
FROM group_weekly_rates_backup;

-- 4. 最近の週利設定状況確認
SELECT 
    week_start_date,
    COUNT(*) as group_count,
    MIN(created_at) as first_created,
    MAX(created_at) as last_created
FROM group_weekly_rates
GROUP BY week_start_date
ORDER BY week_start_date DESC
LIMIT 10;

-- 5. バックアップからの復旧可能データ確認
SELECT 
    week_start_date,
    backup_timestamp,
    COUNT(*) as backup_group_count
FROM group_weekly_rates_backup
GROUP BY week_start_date, backup_timestamp
ORDER BY backup_timestamp DESC
LIMIT 10;

SELECT 'Emergency data recovery investigation completed' as status;
