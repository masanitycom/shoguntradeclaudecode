-- 既存user_nftsテーブルの構造を確認

SELECT 'user_nftsテーブル構造確認' as step;

-- カラム構造を確認
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_nfts' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 既存データのサンプルを確認（最初の5件）
SELECT 'user_nftsサンプルデータ' as step;
SELECT * FROM user_nfts LIMIT 5;

-- テーブルの総レコード数
SELECT 'user_nfts総レコード数' as step, COUNT(*) as count FROM user_nfts;

-- アクティブなレコード数（is_activeカラムがある場合）
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_nfts' 
        AND column_name = 'is_active'
    ) THEN
        PERFORM 1;
        RAISE NOTICE 'is_activeカラムが存在します';
    ELSE
        RAISE NOTICE 'is_activeカラムは存在しません';
    END IF;
END
$$;

SELECT '既存user_nftsテーブル構造確認完了' as result;
