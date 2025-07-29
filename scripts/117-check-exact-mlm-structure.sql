-- mlm_ranksテーブルの正確な構造を確認

-- 1. テーブル構造の詳細確認
SELECT 'Current mlm_ranks structure:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'mlm_ranks' 
ORDER BY ordinal_position;

-- 2. 既存データ確認
SELECT 'Current mlm_ranks data:' as info;
SELECT * FROM mlm_ranks;

-- 3. テーブル定義確認
SELECT 'Table definition:' as info;
SELECT pg_get_tabledef('mlm_ranks'::regclass) as table_definition;
