-- シンプルなテーブル構造確認SQL

-- 1. user_nftsテーブルのカラム一覧
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'user_nfts'
ORDER BY ordinal_position;

-- 2. テーブルの件数確認
SELECT COUNT(*) as total_records FROM user_nfts;

-- 3. 既存データがある場合の最初の1件（全カラム表示）
SELECT * FROM user_nfts LIMIT 1;
