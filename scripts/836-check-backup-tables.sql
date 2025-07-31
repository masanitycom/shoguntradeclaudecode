-- バックアップテーブルの存在確認

SELECT '=== バックアップテーブル確認 ===' as section;

-- 1. 存在するテーブル一覧から確認
SELECT 'バックアップテーブルの存在確認:' as info;
SELECT 
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'public'
  AND (
    table_name LIKE '%backup%'
    OR table_name LIKE '%emergency%'
    OR table_name LIKE '%20250730%'
  )
ORDER BY table_name;

-- 2. user_nftsに関連するテーブル確認
SELECT 'user_nfts関連テーブル:' as info;
SELECT 
    table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name LIKE '%user_nfts%'
ORDER BY table_name;

-- 3. 最近作成されたテーブル確認
SELECT '最近作成されたテーブル:' as recent_tables;
SELECT 
    schemaname,
    tablename,
    tableowner
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename DESC
LIMIT 20;

SELECT '=== バックアップ確認完了 ===' as status;