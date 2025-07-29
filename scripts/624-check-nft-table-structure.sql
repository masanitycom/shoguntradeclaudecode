-- NFTテーブルの実際の構造確認

SELECT 
    '📋 NFTテーブル構造確認' as section,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'nfts' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- NFTとグループの関連確認
SELECT 
    '🔗 NFT-グループ関連確認' as section,
    n.id,
    n.name,
    n.price,
    n.daily_rate_limit,
    'グループ関連なし' as group_info
FROM nfts n
ORDER BY n.price
LIMIT 10;

-- 日利グループテーブル確認
SELECT 
    '📊 日利グループ確認' as section,
    id,
    group_name,
    daily_rate_limit,
    description
FROM daily_rate_groups
ORDER BY daily_rate_limit;
