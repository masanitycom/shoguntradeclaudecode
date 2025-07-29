-- daily_rewardsテーブルの構造確認

-- 1. daily_rewardsテーブルのカラム構造
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. daily_rewardsテーブルの制約確認
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'daily_rewards'
AND tc.table_schema = 'public';

-- 3. 外部キー関係の確認
SELECT 
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name = 'daily_rewards'
AND tc.table_schema = 'public';

-- 4. インデックス確認
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'daily_rewards'
AND schemaname = 'public';
