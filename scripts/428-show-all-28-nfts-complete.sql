-- 全28個のNFTの完全な情報を表示

-- 1. 全28個のNFTを1つずつ完全表示
SELECT 
    '🎯 NFT詳細 #' || ROW_NUMBER() OVER (ORDER BY price, name) as nft_info,
    ROW_NUMBER() OVER (ORDER BY price, name) as no,
    id,
    name,
    price,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as current_rate,
    is_special,
    is_active,
    description,
    image_url,
    created_at,
    updated_at
FROM nfts
WHERE is_active = true
ORDER BY price, name;

-- 2. 価格順で全NFTリスト
SELECT 
    '📋 価格順NFTリスト' as section,
    name,
    '$' || price as price_display,
    (daily_rate_limit * 100) || '%' as rate,
    CASE WHEN is_special THEN '特別NFT' ELSE '通常NFT' END as type
FROM nfts
WHERE is_active = true
ORDER BY price;

-- 3. 現在の日利上限別グループ
SELECT 
    '📊 現在の日利上限別' as section,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    COUNT(*) as count,
    STRING_AGG(name || '($' || price || ')', ', ' ORDER BY price) as nft_list
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;

-- 4. 特別NFTと通常NFTの分類
SELECT 
    '🏷️ 特別/通常NFT分類' as section,
    CASE WHEN is_special THEN '特別NFT' ELSE '通常NFT' END as type,
    COUNT(*) as count,
    STRING_AGG(name || '($' || price || ',' || (daily_rate_limit*100) || '%)', ', ' ORDER BY price) as details
FROM nfts
WHERE is_active = true
GROUP BY is_special
ORDER BY is_special;

-- 5. 全NFTの詳細テーブル形式
SELECT 
    '📋 全NFT詳細テーブル' as section,
    ROW_NUMBER() OVER (ORDER BY price) as no,
    name,
    price,
    daily_rate_limit,
    is_special,
    is_active,
    LEFT(description, 50) as description_short,
    created_at::date as created_date
FROM nfts
WHERE is_active = true
ORDER BY price;

-- 6. アルファベット順NFTリスト
SELECT 
    '🔤 アルファベット順' as section,
    ROW_NUMBER() OVER (ORDER BY name) as no,
    name,
    price,
    (daily_rate_limit * 100) || '%' as rate,
    is_special
FROM nfts
WHERE is_active = true
ORDER BY name;

-- 7. 日利上限順NFTリスト
SELECT 
    '📈 日利上限順' as section,
    ROW_NUMBER() OVER (ORDER BY daily_rate_limit, price) as no,
    name,
    price,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate,
    is_special
FROM nfts
WHERE is_active = true
ORDER BY daily_rate_limit, price;

-- 8. 作成日順NFTリスト
SELECT 
    '📅 作成日順' as section,
    ROW_NUMBER() OVER (ORDER BY created_at) as no,
    name,
    price,
    (daily_rate_limit * 100) || '%' as rate,
    created_at::date as created_date,
    is_special
FROM nfts
WHERE is_active = true
ORDER BY created_at;

-- 9. 全NFTの統計情報
SELECT 
    '📊 統計情報' as section,
    COUNT(*) as total_nfts,
    COUNT(DISTINCT daily_rate_limit) as unique_rates,
    MIN(price) as min_price,
    MAX(price) as max_price,
    AVG(price) as avg_price,
    COUNT(CASE WHEN is_special THEN 1 END) as special_count,
    COUNT(CASE WHEN NOT is_special THEN 1 END) as normal_count,
    STRING_AGG(DISTINCT (daily_rate_limit * 100) || '%', ', ' ORDER BY (daily_rate_limit * 100) || '%') as all_rates
FROM nfts
WHERE is_active = true;

-- 10. 非アクティブNFTも含む全データ
SELECT 
    '🗂️ 全NFT（非アクティブ含む）' as section,
    ROW_NUMBER() OVER (ORDER BY is_active DESC, price) as no,
    name,
    price,
    (daily_rate_limit * 100) || '%' as rate,
    is_special,
    is_active,
    created_at::date as created_date
FROM nfts
ORDER BY is_active DESC, price;
