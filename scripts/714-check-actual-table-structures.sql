-- 実際のテーブル構造を詳細確認

-- 1. group_weekly_rates テーブルの詳細構造
SELECT 
    'group_weekly_rates table structure:' as info,
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates' 
ORDER BY ordinal_position;

-- 2. group_weekly_rates_backup テーブルの詳細構造
SELECT 
    'group_weekly_rates_backup table structure:' as info,
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates_backup' 
ORDER BY ordinal_position;

-- 3. 実際のデータサンプル確認
SELECT 
    'Sample data from group_weekly_rates:' as info,
    *
FROM group_weekly_rates
LIMIT 3;

-- 4. バックアップテーブルのサンプル確認
SELECT 
    'Sample data from group_weekly_rates_backup:' as info,
    *
FROM group_weekly_rates_backup
LIMIT 3;

-- 5. テーブル間の構造差異確認
WITH main_cols AS (
    SELECT column_name, data_type
    FROM information_schema.columns 
    WHERE table_name = 'group_weekly_rates'
),
backup_cols AS (
    SELECT column_name, data_type
    FROM information_schema.columns 
    WHERE table_name = 'group_weekly_rates_backup'
)
SELECT 
    'Column differences:' as info,
    COALESCE(m.column_name, b.column_name) as column_name,
    CASE 
        WHEN m.column_name IS NULL THEN 'Only in backup'
        WHEN b.column_name IS NULL THEN 'Only in main'
        WHEN m.data_type != b.data_type THEN 'Type mismatch'
        ELSE 'Match'
    END as status,
    m.data_type as main_type,
    b.data_type as backup_type
FROM main_cols m
FULL OUTER JOIN backup_cols b ON m.column_name = b.column_name
WHERE m.column_name IS NULL OR b.column_name IS NULL OR m.data_type != b.data_type;
