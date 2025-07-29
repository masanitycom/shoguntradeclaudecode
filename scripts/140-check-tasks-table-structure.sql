-- tasksテーブルの現在の構造を確認

SELECT '=== Tasks テーブル構造確認 ===' as section;

-- tasksテーブルの詳細構造
SELECT 
    column_name, 
    data_type, 
    character_maximum_length,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'tasks' 
AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT '=== Tasks テーブルのサンプルデータ ===' as section;

-- tasksテーブルの実際のデータ確認（最大5件）
SELECT *
FROM tasks 
ORDER BY created_at DESC
LIMIT 5;

SELECT '=== Tasks テーブル統計 ===' as section;

-- テーブル統計
SELECT 
    COUNT(*) as total_tasks,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_tasks,
    COUNT(CASE WHEN is_active = false THEN 1 END) as inactive_tasks
FROM tasks;
