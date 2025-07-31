-- usersテーブルの構造確認

SELECT '=== USERS TABLE STRUCTURE ===' as section;

-- 1. usersテーブルのカラム情報
SELECT 'Users table columns:' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'users'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. サンプルデータで実際のカラムを確認
SELECT 'Sample user data (first row):' as info;
SELECT * FROM users LIMIT 1;