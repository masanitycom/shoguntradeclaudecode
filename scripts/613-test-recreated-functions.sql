-- 再作成した関数のテスト

-- 1. まずテーブル構造を確認
SELECT 'Checking group_weekly_rates_backup table structure...' as status;

SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates_backup' 
ORDER BY ordinal_position;

-- 2. テーブルが存在するか確認
SELECT 'Checking if backup table exists...' as status;

SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_name = 'group_weekly_rates_backup'
) as backup_table_exists;

-- 3. daily_rate_groups テーブル構造確認
SELECT 'Checking daily_rate_groups table structure...' as status;

SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'daily_rate_groups' 
ORDER BY ordinal_position;

-- 4. group_weekly_rates テーブル構造確認
SELECT 'Checking group_weekly_rates table structure...' as status;

SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates' 
ORDER BY ordinal_position;

-- 5. 基本的な関数テスト（エラーが出ないもの）
SELECT 'Testing show_available_groups function...' as status;

SELECT * FROM show_available_groups();

-- 6. システム状況確認
SELECT 'Testing get_system_status function...' as status;

SELECT * FROM get_system_status();
