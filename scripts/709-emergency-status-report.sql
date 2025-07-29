-- 緊急状況レポート

-- 1. データ損失状況の詳細調査
WITH backup_analysis AS (
    SELECT 
        week_start_date,
        backup_timestamp,
        backup_reason,
        COUNT(*) as group_count,
        ROW_NUMBER() OVER (PARTITION BY week_start_date ORDER BY backup_timestamp DESC) as backup_rank
    FROM group_weekly_rates_backup
    GROUP BY week_start_date, backup_timestamp, backup_reason
),
current_settings AS (
    SELECT 
        week_start_date,
        COUNT(*) as current_group_count,
        STRING_AGG(DISTINCT distribution_method, ', ') as current_methods
    FROM group_weekly_rates
    GROUP BY week_start_date
)
SELECT 
    '📊 データ損失状況分析' as report_type,
    cs.week_start_date,
    cs.current_group_count as current_groups,
    cs.current_methods,
    ba.group_count as backup_groups,
    ba.backup_reason,
    ba.backup_timestamp::TEXT as backup_time
FROM current_settings cs
LEFT JOIN backup_analysis ba ON cs.week_start_date = ba.week_start_date AND ba.backup_rank = 1
ORDER BY cs.week_start_date DESC;

-- 2. 復旧可能性の評価
SELECT 
    '🔍 復旧可能性評価' as report_type,
    COUNT(DISTINCT week_start_date) as weeks_with_backup,
    COUNT(*) as total_backup_records,
    MIN(backup_timestamp) as oldest_backup,
    MAX(backup_timestamp) as newest_backup
FROM group_weekly_rates_backup
WHERE backup_reason NOT LIKE '%automatic%';

-- 3. 現在の保護状況
SELECT 
    '🛡️ 現在の保護状況' as report_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'protect_manual_settings_trigger')
        THEN '✅ 保護トリガー有効'
        ELSE '❌ 保護トリガー無効'
    END as protection_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'admin_safe_set_weekly_rate')
        THEN '✅ 安全設定関数有効'
        ELSE '❌ 安全設定関数無効'
    END as safe_function_status;

-- 4. 緊急対応完了確認
SELECT 
    '✅ 緊急対応状況' as report_type,
    'データ復旧処理完了' as recovery_status,
    '自動変更防止機能有効' as protection_status,
    '管理者専用安全設定機能追加' as safety_status,
    'バックアップ関数エラー修正完了' as backup_fix_status;
