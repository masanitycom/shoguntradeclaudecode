-- 現在のNFTの日利上限を確認

-- NFTテーブルの構造確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'nfts'
ORDER BY ordinal_position;

-- 現在のNFTと日利上限を確認
SELECT 
    n.id,
    n.name,
    n.price,
    n.daily_rate_limit,
    n.is_special,
    drg.group_name,
    drg.description
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
ORDER BY n.price, n.is_special;

-- 日利上限グループの確認
SELECT 
    id,
    group_name,
    daily_rate_limit,
    description,
    created_at
FROM daily_rate_groups
ORDER BY daily_rate_limit;

-- NFTの価格別集計
SELECT 
    n.price,
    n.daily_rate_limit,
    COUNT(*) as nft_count,
    STRING_AGG(n.name, ', ') as nft_names
FROM nfts n
GROUP BY n.price, n.daily_rate_limit
ORDER BY n.price;

SELECT '現在のNFT日利上限を確認しました' as status;
