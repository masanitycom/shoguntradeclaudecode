-- 削除機能のテスト

-- 1. 現在の週利設定を確認
SELECT 
    week_start_date,
    COUNT(*) as group_count,
    STRING_AGG(drg.group_name, ', ') as groups
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
GROUP BY week_start_date
ORDER BY week_start_date DESC
LIMIT 10;

-- 2. 削除可能性をテスト（実際には削除しない）
SELECT * FROM safe_delete_weekly_rates('2025-02-10');

-- 3. バックアップテーブルの状況確認
SELECT 
    COUNT(*) as total_backups,
    COUNT(DISTINCT week_start_date) as unique_weeks
FROM group_weekly_rates_backup;

-- 4. 関数の存在確認
SELECT 
    proname as function_name,
    pg_get_function_arguments(oid) as arguments
FROM pg_proc 
WHERE proname LIKE '%delete%weekly%' 
OR proname LIKE '%admin_delete%';
