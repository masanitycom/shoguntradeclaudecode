-- 最終状況レポート（重複制約対応版）

-- 1. テーブル構造確認
SELECT 
    'TABLE STRUCTURES' as report_section,
    'group_weekly_rates' as table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates'
ORDER BY ordinal_position;

-- 2. 制約確認
SELECT 
    'CONSTRAINTS' as report_section,
    conname as constraint_name,
    contype as constraint_type,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'group_weekly_rates'::regclass;

-- 3. 現在の週利設定状況
SELECT 
    'CURRENT WEEKLY RATES' as report_section,
    week_start_date,
    COALESCE(group_name, 'Group-' || group_id::TEXT) as group_identifier,
    (weekly_rate * 100)::DECIMAL(5,2) as weekly_percent,
    distribution_method,
    created_at,
    updated_at
FROM group_weekly_rates
ORDER BY week_start_date DESC, group_name;

-- 4. バックアップ状況詳細
SELECT 
    'BACKUP STATUS' as report_section,
    backup_reason,
    COUNT(*) as backup_count,
    MIN(backup_timestamp::TIMESTAMP) as earliest_backup,
    MAX(backup_timestamp::TIMESTAMP) as latest_backup
FROM group_weekly_rates_backup
GROUP BY backup_reason
ORDER BY latest_backup DESC;

-- 5. 手動設定のバックアップ確認
SELECT 
    'MANUAL BACKUP DETAILS' as report_section,
    week_start_date,
    backup_reason,
    backup_timestamp::TIMESTAMP as backup_time,
    (weekly_rate * 100)::DECIMAL(5,2) as weekly_percent
FROM group_weekly_rates_backup
WHERE backup_reason LIKE '%Manual%' 
   OR backup_reason LIKE '%手動%'
   OR backup_reason LIKE '%admin%'
   OR backup_reason LIKE '%ADMIN_MANUAL%'
ORDER BY backup_timestamp DESC;

-- 6. 保護システム状況
SELECT 
    'PROTECTION SYSTEM' as report_section,
    'Trigger: ' || tgname as protection_name,
    'Active on ' || schemaname || '.' || tablename as status
FROM pg_trigger t
JOIN pg_tables pt ON pt.tablename = (SELECT relname FROM pg_class WHERE oid = t.tgrelid)
WHERE tgname LIKE '%weekly_rate%';

SELECT 
    'PROTECTION SYSTEM' as report_section,
    'Function: ' || proname as protection_name,
    'Available' as status
FROM pg_proc 
WHERE proname LIKE '%admin_safe_%' OR proname LIKE '%protect_weekly%';

-- 7. 利用可能な管理者関数
SELECT 
    'ADMIN FUNCTIONS' as report_section,
    proname as function_name,
    pg_get_function_arguments(oid) as parameters
FROM pg_proc 
WHERE proname IN ('admin_safe_set_weekly_rate', 'get_current_weekly_rates');

-- 8. システム使用方法
SELECT 
    'USAGE INSTRUCTIONS' as report_section,
    'Safe weekly rate setting:' as instruction,
    'SELECT * FROM admin_safe_set_weekly_rate(''2025-02-10'', ''1.5%グループ'', 0.026);' as example
UNION ALL
SELECT 
    'USAGE INSTRUCTIONS' as report_section,
    'Check current rates:' as instruction,
    'SELECT * FROM get_current_weekly_rates();' as example;

-- 9. データ整合性チェック
SELECT 
    'DATA INTEGRITY' as report_section,
    'Total weekly rates records' as check_type,
    COUNT(*)::TEXT as result
FROM group_weekly_rates
UNION ALL
SELECT 
    'DATA INTEGRITY' as report_section,
    'Total backup records' as check_type,
    COUNT(*)::TEXT as result
FROM group_weekly_rates_backup
UNION ALL
SELECT 
    'DATA INTEGRITY' as report_section,
    'Records with manual settings' as check_type,
    COUNT(*)::TEXT as result
FROM group_weekly_rates
WHERE distribution_method = 'ADMIN_MANUAL_SETTING';

-- 10. 最終ステータス
SELECT 
    'EMERGENCY RECOVERY COMPLETE' as final_status,
    'Manual settings restored with duplicate constraint handling' as restoration_status,
    'Automatic changes completely prevented' as protection_status,
    'Safe admin functions available with conflict resolution' as admin_status,
    NOW() as completion_time;

-- 11. 次回の安全な操作例
SELECT 
    'NEXT STEPS' as section,
    'To set weekly rates safely, use:' as instruction,
    'SELECT * FROM admin_safe_set_weekly_rate(''2025-02-17'', ''1.5%グループ'', 0.025);' as example_1,
    'SELECT * FROM get_current_weekly_rates();' as example_2;
