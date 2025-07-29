-- 2025年2月10日週の設定準備

-- 1. 日付検証
SELECT 
    '2025-02-10'::DATE as target_date,
    EXTRACT(DOW FROM '2025-02-10'::DATE) as day_of_week,
    CASE WHEN EXTRACT(DOW FROM '2025-02-10'::DATE) = 1 THEN '月曜日 ✓' ELSE '月曜日ではありません ✗' END as validation,
    '2025-02-14'::DATE as week_end_date;

-- 2. 現在のグループ確認
SELECT 'Current NFT Groups:' as info;
SELECT * FROM show_available_groups();

-- 3. 推奨設定値表示
SELECT 'Recommended Weekly Rate Settings for 2025-02-10:' as info;

-- 4. 設定用SQLコマンド生成
SELECT '-- Execute the following commands to set up February 10, 2025 week rates:' as setup_commands;

SELECT format('
-- Set weekly rates for %s week (2025-02-10 to 2025-02-14)
SELECT set_weekly_rates_for_all_groups(
    ''%s''::DATE,  -- week_start_date
    2.6,           -- total_weekly_rate (2.6%%)
    ''February 10 week setup''  -- reason
);
', '2025-02-10', '2025-02-10') as sql_command;

-- 5. バックアップ確認
SELECT 'Current backup status:' as info;
SELECT COUNT(*) as total_backups FROM group_weekly_rates_backup;

-- 6. 既存データ確認
SELECT 'Checking for existing 2025-02-10 data:' as info;
SELECT 
    COUNT(*) as existing_records,
    CASE WHEN COUNT(*) > 0 THEN 'データが既に存在します - 上書きされます' ELSE '新規設定可能' END as status
FROM group_weekly_rates 
WHERE week_start_date = '2025-02-10'::DATE;

SELECT 'Preparation completed. Ready to execute setup.' as status;
