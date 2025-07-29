-- =========================================================
-- tasksテーブルの実際の構造を詳細確認
-- =========================================================

-- 1. テーブル構造の確認
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default,
  character_maximum_length
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'tasks'
ORDER BY ordinal_position;

-- 2. 制約の確認
SELECT 
  tc.constraint_name,
  tc.constraint_type,
  kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
  ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'public' 
  AND tc.table_name = 'tasks';

-- 3. 現在のデータ件数
SELECT COUNT(*) as total_count FROM public.tasks;

-- 4. 既存データのサンプル（あれば）
SELECT 
  id,
  title,
  description,
  task_type,
  questions,
  question,
  option1,
  option2,
  option3,
  is_active,
  created_at
FROM public.tasks
LIMIT 5;
