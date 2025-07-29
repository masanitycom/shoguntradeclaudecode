-- user_nfts テーブルの正確な構造を確認
SELECT 
    '🎯 user_nfts テーブル構造' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_nfts' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- サンプルデータも確認
SELECT 
    '🎯 user_nfts サンプルデータ' as info,
    *
FROM user_nfts 
LIMIT 3;
