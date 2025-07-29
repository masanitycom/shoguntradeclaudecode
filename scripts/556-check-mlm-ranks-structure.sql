-- mlm_ranksテーブルの実際の構造を詳細確認

SELECT 
    '📋 mlm_ranksテーブルの詳細構造' as info,
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default
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

-- user_rank_historyテーブルの構造も確認
SELECT 
    '📋 user_rank_historyテーブルの構造' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_rank_history' 
AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT '✅ MLMランク関連テーブル構造確認完了' as final_status;
