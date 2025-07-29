-- usersテーブルの正確なカラム名を確認
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- OHTAKIYOユーザーの実際のデータも確認
SELECT * FROM users WHERE name LIKE '%OHTAKI%' OR email LIKE '%ohtaki%' LIMIT 1;
