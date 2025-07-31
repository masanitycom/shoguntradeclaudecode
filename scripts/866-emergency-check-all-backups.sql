-- 全バックアップテーブル緊急確認

SELECT 
    table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND (
    table_name LIKE '%backup%'
    OR table_name LIKE '%emergency%'
    OR table_name LIKE '%20250730%'
    OR table_name LIKE '%20250731%'
  )
ORDER BY table_name;