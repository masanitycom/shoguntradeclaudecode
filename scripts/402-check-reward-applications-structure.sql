-- reward_applications テーブル構造確認
SELECT 
    '📋 reward_applications テーブル構造' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'reward_applications' 
  AND table_schema = 'public'
ORDER BY ordinal_position;
