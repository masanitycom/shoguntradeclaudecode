-- 週ごと削除機能のテスト

-- 1. 現在の週利設定を確認
SELECT 
    '=== 現在の週利設定 ===' as section,
    week_start_date,
    COUNT(*) as group_count,
    STRING_AGG(drg.group_name, ', ') as groups
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
GROUP BY week_start_date
ORDER BY week_start_date DESC;

-- 2. 削除前確認のテスト（実際には削除しない）
SELECT 
    '=== 削除前確認テスト ===' as section,
    *
FROM check_weekly_rates_for_deletion('2025-02-10');

-- 3. バックアップテーブルの状況確認
SELECT 
    '=== バックアップ状況 ===' as section,
    COUNT(*) as total_backups,
    COUNT(DISTINCT week_start_date) as unique_weeks,
    MIN(backup_timestamp) as oldest_backup,
    MAX(backup_timestamp) as newest_backup
FROM group_weekly_rates_backup;

-- 4. 関数の存在確認
SELECT 
    '=== 削除関数確認 ===' as section,
    proname as function_name,
    pg_get_function_arguments(oid) as arguments
FROM pg_proc 
WHERE proname LIKE '%delete%weekly%' 
OR proname LIKE '%check%weekly%'
OR proname LIKE '%restore%weekly%'
ORDER BY proname;
