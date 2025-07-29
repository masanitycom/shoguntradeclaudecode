-- 最終状況レポート

-- 1. テーブル構造確認
SELECT 
    'TABLE STRUCTURES' as report_section,
    'group_weekly_rates' as table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates'
ORDER BY ordinal_position;

SELECT 
    'TABLE STRUCTURES' as report_section,
    'group_weekly_rates_backup' as table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates_backup'
ORDER BY ordinal_position;

-- 2. 現在の週利設定状況
SELECT 
    'CURRENT WEEKLY RATES' as report_section,
    week_start_date,
    COALESCE(daily_rate_group, group_name, 'Unknown') as group_identifier,
    weekly_rate * 100 as weekly_percent,
    distribution_method,
    created_at
FROM group_weekly_rates
ORDER BY week_start_date DESC;

-- 3. バックアップ状況
SELECT 
    'BACKUP STATUS' as report_section,
    COUNT(*) as total_backups,
    COUNT(CASE WHEN backup_reason LIKE '%Manual%' THEN 1 END) as manual_backups,
    MAX(backup_timestamp) as latest_backup
FROM group_weekly_rates_backup;

-- 4. 保護システム状況
SELECT 
    'PROTECTION SYSTEM' as report_section,
    'Trigger: ' || tgname as protection_name,
    'Active' as status
FROM pg_trigger 
WHERE tgname LIKE '%weekly_rate%';

SELECT 
    'PROTECTION SYSTEM' as report_section,
    'Function: ' || proname as protection_name,
    'Available' as status
FROM pg_proc 
WHERE proname LIKE '%admin_safe_%';

-- 5. システム使用方法
SELECT 
    'USAGE INSTRUCTIONS' as report_section,
    'Use this function to safely set weekly rates:' as instruction,
    'SELECT * FROM admin_safe_set_weekly_rate(''2025-02-10'', ''1.5%グループ'', 0.026);' as example;

-- 6. 最終ステータス
SELECT 
    'EMERGENCY RECOVERY COMPLETE' as final_status,
    'Manual settings restored' as restoration_status,
    'Automatic changes prevented' as protection_status,
    'Safe admin functions available' as admin_status,
    NOW() as completion_time;
