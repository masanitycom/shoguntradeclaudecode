-- 実際のバックアップテーブル構造を確認

SELECT 'Checking actual backup table structure...' as status;

-- 1. テーブルが存在するかチェック
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'group_weekly_rates_backup'
        ) 
        THEN 'Table exists'
        ELSE 'Table does not exist'
    END as table_status;

-- 2. 実際のカラム構造を確認
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates_backup' 
ORDER BY ordinal_position;

-- 3. group_weekly_ratesテーブルの構造も確認
SELECT 'Checking group_weekly_rates table structure...' as status;

SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates' 
ORDER BY ordinal_position;

-- 4. 既存のバックアップデータがあるかチェック
SELECT 
    COUNT(*) as backup_record_count,
    MIN(week_start_date) as earliest_week,
    MAX(week_start_date) as latest_week
FROM group_weekly_rates_backup;
