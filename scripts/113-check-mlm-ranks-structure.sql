-- mlm_ranksテーブルの構造確認

-- 1. mlm_ranksテーブルの構造を確認
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'mlm_ranks'
ORDER BY ordinal_position;

-- 2. 現在のデータを確認
SELECT 'Current mlm_ranks data:' as info;
SELECT * FROM mlm_ranks LIMIT 5;
