-- user_rank_historyテーブルの構造を確認

-- 1. テーブル構造の詳細確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_rank_history' 
ORDER BY ordinal_position;

-- 2. 既存データの確認
SELECT COUNT(*) as total_records FROM user_rank_history;

-- 3. サンプルデータの確認
SELECT * FROM user_rank_history LIMIT 5;

-- 4. 現在アクティブなランクの確認
SELECT 
    rank_level,
    COUNT(*) as count
FROM user_rank_history 
WHERE is_current = true 
GROUP BY rank_level 
ORDER BY rank_level;
