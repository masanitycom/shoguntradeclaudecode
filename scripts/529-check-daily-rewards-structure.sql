-- daily_rewardsテーブルの正確な構造を確認

SELECT 
    '📋 daily_rewards テーブル構造' as table_info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- サンプルデータも確認
SELECT 
    '📊 daily_rewards サンプルデータ' as data_info,
    *
FROM daily_rewards 
LIMIT 3;

-- テーブルの制約情報
SELECT 
    '🔗 daily_rewards 制約情報' as constraint_info,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'daily_rewards' 
    AND table_schema = 'public';

-- インデックス情報
SELECT 
    '📇 daily_rewards インデックス情報' as index_info,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'daily_rewards' 
    AND schemaname = 'public';
