-- より詳細なテーブル構造確認

-- 1. user_nftsテーブルの全カラム情報を表示
\d user_nfts

-- 2. 既存データの構造を実際のデータで確認
SELECT 'user_nftsの実際のデータ構造確認' as info;

-- 3. テーブルが空でない場合、最初の1件を表示
DO $$
DECLARE
    rec RECORD;
    col_info TEXT := '';
BEGIN
    -- テーブルの件数確認
    EXECUTE 'SELECT COUNT(*) FROM user_nfts' INTO rec;
    RAISE NOTICE 'user_nftsテーブルの総件数: %', rec.count;
    
    -- データがある場合、1件表示
    IF rec.count > 0 THEN
        RAISE NOTICE '=== 既存データサンプル ===';
        FOR rec IN SELECT * FROM user_nfts LIMIT 1 LOOP
            RAISE NOTICE 'サンプルレコード: %', rec;
        END LOOP;
    ELSE
        RAISE NOTICE 'user_nftsテーブルは空です';
    END IF;
END
$$;

-- 4. カラム名を個別に確認
SELECT 
    'カラム情報' as type,
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'user_nfts'
ORDER BY ordinal_position;
