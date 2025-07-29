-- mlm_ranksテーブルの実際の構造を詳細確認

SELECT 
    '📋 mlm_ranksテーブルの詳細構造' as info,
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default,
    CASE 
        WHEN is_nullable = 'NO' THEN '必須'
        ELSE '任意'
    END as constraint_type
FROM information_schema.columns 
WHERE table_name = 'mlm_ranks' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 現在のmlm_ranksテーブルの全データを確認
SELECT 
    '📊 mlm_ranksテーブルの現在のデータ' as info,
    *
FROM mlm_ranks 
ORDER BY rank_level;

-- テーブルの制約を確認
SELECT 
    '🔒 mlm_ranksテーブルの制約' as info,
    conname as constraint_name,
    contype as constraint_type,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'mlm_ranks'::regclass;

SELECT '✅ MLMランクテーブル構造詳細確認完了' as final_status;
