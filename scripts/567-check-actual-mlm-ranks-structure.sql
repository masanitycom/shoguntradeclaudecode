-- mlm_ranksテーブルの実際の構造を正確に確認（Supabase対応版）

SELECT 
    '📋 mlm_ranksテーブルの実際のカラム構造' as info,
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'mlm_ranks' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 現在のデータも確認
SELECT '📊 現在のmlm_ranksデータ' as info;
SELECT * FROM mlm_ranks ORDER BY rank_level;

-- 全テーブル一覧を確認
SELECT 
    '📋 全テーブル一覧' as info,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
ORDER BY table_name;

SELECT '✅ 実際の構造確認完了' as final_status;
