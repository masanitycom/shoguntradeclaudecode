-- テーブル構造確認

SELECT 'user_rank_history table structure:' as check_type;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'user_rank_history'
  AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 'Sample user_rank_history data:' as sample_data;
SELECT * FROM user_rank_history 
WHERE user_id = '00000000-0000-0000-0000-000000000001'
LIMIT 3;