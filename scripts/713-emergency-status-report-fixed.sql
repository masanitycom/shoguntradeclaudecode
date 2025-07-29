-- 緊急状況レポート（最終確認）

-- 1. 現在の週利設定状況
SELECT 
    'CURRENT WEEKLY RATES STATUS' as report_section,
    week_start_date,
    daily_rate_group,
    weekly_rate,
    distribution_method,
    created_at,
    updated_at
FROM group_weekly_rates
ORDER BY week_start_date DESC, daily_rate_group;

-- 2. バックアップ状況確認
SELECT 
    'BACKUP STATUS' as report_section,
    week_start_date,
    backup_timestamp,
    backup_reason,
    COUNT(*) as backup_count
FROM group_weekly_rates_backup
GROUP BY week_start_date, backup_timestamp, backup_reason
ORDER BY backup_timestamp DESC
LIMIT 20;

-- 3. 最近の変更履歴
SELECT 
    'RECENT CHANGES' as report_section,
    week_start_date,
    daily_rate_group,
    weekly_rate,
    distribution_method,
    updated_at
FROM group_weekly_rates
WHERE updated_at >= NOW() - INTERVAL '24 hours'
ORDER BY updated_at DESC;

-- 4. システム保護状況確認
SELECT 
    'SYSTEM PROTECTION STATUS' as report_section,
    'Trigger: ' || tgname as protection_name,
    'Active' as status
FROM pg_trigger 
WHERE tgname LIKE '%weekly_rate%';

-- 5. 関数保護状況確認
SELECT 
    'FUNCTION PROTECTION STATUS' as report_section,
    proname as function_name,
    'Available' as status
FROM pg_proc 
WHERE proname LIKE '%admin_safe_%';

-- 6. 総合ステータス
SELECT 
    'EMERGENCY RECOVERY SUMMARY' as report_section,
    (SELECT COUNT(*) FROM group_weekly_rates) as current_weekly_rates,
    (SELECT COUNT(*) FROM group_weekly_rates_backup) as total_backups,
    (SELECT COUNT(*) FROM group_weekly_rates WHERE distribution_method = 'admin_manual') as manual_settings,
    NOW() as report_timestamp;

SELECT 'Emergency status report completed' as final_status;
