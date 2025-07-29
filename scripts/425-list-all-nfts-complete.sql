-- 全NFTの完全なリストを出力

-- 1. 全NFTの詳細リスト（価格順）
SELECT 
    '📋 全NFT完全リスト' as section,
    ROW_NUMBER() OVER (ORDER BY price) as no,
    id,
    name,
    price,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as current_rate,
    is_special,
    is_active,
    description,
    image_url,
    created_at::date as created_date,
    updated_at::date as updated_date
FROM nfts
ORDER BY price, name;

-- 2. アクティブNFTのみ（価格順）
SELECT 
    '✅ アクティブNFTのみ' as section,
    ROW_NUMBER() OVER (ORDER BY price) as no,
    name,
    '$' || price as price_display,
    (daily_rate_limit * 100) || '%' as rate,
    CASE WHEN is_special THEN '特別' ELSE '通常' END as type,
    description
FROM nfts
WHERE is_active = true
ORDER BY price, name;

-- 3. 価格帯別グループ分け
SELECT 
    '💰 価格帯別グループ分け' as section,
    CASE 
        WHEN price <= 600 THEN '1. $0-600'
        WHEN price <= 1000 THEN '2. $601-1000'
        WHEN price <= 5000 THEN '3. $1001-5000'
        WHEN price <= 10000 THEN '4. $5001-10000'
        WHEN price <= 30000 THEN '5. $10001-30000'
        WHEN price <= 50000 THEN '6. $30001-50000'
        ELSE '7. $50001+'
    END as price_group,
    COUNT(*) as nft_count,
    STRING_AGG(name || '($' || price || ')', ', ' ORDER BY price) as nft_list
FROM nfts
WHERE is_active = true
GROUP BY 
    CASE 
        WHEN price <= 600 THEN '1. $0-600'
        WHEN price <= 1000 THEN '2. $601-1000'
        WHEN price <= 5000 THEN '3. $1001-5000'
        WHEN price <= 10000 THEN '4. $5001-10000'
        WHEN price <= 30000 THEN '5. $10001-30000'
        WHEN price <= 50000 THEN '6. $30001-50000'
        ELSE '7. $50001+'
    END
ORDER BY 
    CASE 
        WHEN price <= 600 THEN '1. $0-600'
        WHEN price <= 1000 THEN '2. $601-1000'
        WHEN price <= 5000 THEN '3. $1001-5000'
        WHEN price <= 10000 THEN '4. $5001-10000'
        WHEN price <= 30000 THEN '5. $10001-30000'
        WHEN price <= 50000 THEN '6. $30001-50000'
        ELSE '7. $50001+'
    END;

-- 4. 現在の日利上限別グループ分け
SELECT 
    '📊 現在の日利上限別グループ分け' as section,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    COUNT(*) as nft_count,
    MIN(price) as min_price,
    MAX(price) as max_price,
    STRING_AGG(name || '($' || price || ')', ', ' ORDER BY price) as nft_list
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;

-- 5. 特別NFTと通常NFTの分類
SELECT 
    '🏷️ 特別NFTと通常NFTの分類' as section,
    CASE WHEN is_special THEN '特別NFT' ELSE '通常NFT' END as nft_type,
    COUNT(*) as count,
    MIN(price) as min_price,
    MAX(price) as max_price,
    AVG(price) as avg_price,
    STRING_AGG(name || '($' || price || ',' || (daily_rate_limit*100) || '%)', ', ' ORDER BY price) as details
FROM nfts
WHERE is_active = true
GROUP BY is_special
ORDER BY is_special;

-- 6. 個別NFT詳細（1つずつ）
SELECT 
    '🔍 個別NFT詳細' as section,
    name,
    price,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as current_rate,
    is_special,
    CASE 
        WHEN price <= 600 THEN '0.5%が適切'
        WHEN price <= 1000 THEN '1.0%が適切'
        WHEN price <= 5000 THEN '1.0%が適切'
        WHEN price <= 10000 THEN '1.25%が適切'
        WHEN price <= 30000 THEN '1.5%が適切'
        WHEN price <= 50000 THEN '1.75%が適切'
        ELSE '2.0%が適切'
    END as suggested_rate,
    CASE 
        WHEN price <= 600 THEN 0.005
        WHEN price <= 1000 THEN 0.010
        WHEN price <= 5000 THEN 0.010
        WHEN price <= 10000 THEN 0.0125
        WHEN price <= 30000 THEN 0.015
        WHEN price <= 50000 THEN 0.0175
        ELSE 0.020
    END as suggested_value,
    CASE 
        WHEN (price <= 600 AND daily_rate_limit = 0.005) OR
             (price > 600 AND price <= 5000 AND daily_rate_limit = 0.010) OR
             (price > 5000 AND price <= 10000 AND daily_rate_limit = 0.0125) OR
             (price > 10000 AND price <= 30000 AND daily_rate_limit = 0.015) OR
             (price > 30000 AND price <= 50000 AND daily_rate_limit = 0.0175) OR
             (price > 50000 AND daily_rate_limit = 0.020)
        THEN '✅ 正常'
        ELSE '❌ 要修正'
    END as status
FROM nfts
WHERE is_active = true
ORDER BY price, name;

-- 7. 統計サマリー
SELECT 
    '📈 統計サマリー' as section,
    COUNT(*) as total_nfts,
    COUNT(DISTINCT daily_rate_limit) as unique_rates,
    MIN(price) as min_price,
    MAX(price) as max_price,
    AVG(price) as avg_price,
    COUNT(CASE WHEN is_special THEN 1 END) as special_nfts,
    COUNT(CASE WHEN NOT is_special THEN 1 END) as normal_nfts
FROM nfts
WHERE is_active = true;

-- 8. 全28個のNFTを1つずつ表示
SELECT 
    '🎯 全28個のNFT一覧' as section,
    ROW_NUMBER() OVER (ORDER BY price, name) as no,
    name,
    '$' || price as price,
    (daily_rate_limit * 100) || '%' as current_rate,
    CASE WHEN is_special THEN '特別' ELSE '通常' END as type,
    CASE 
        WHEN price <= 600 THEN '0.5%'
        WHEN price <= 5000 THEN '1.0%'
        WHEN price <= 10000 THEN '1.25%'
        WHEN price <= 30000 THEN '1.5%'
        WHEN price <= 50000 THEN '1.75%'
        ELSE '2.0%'
    END as should_be,
    CASE 
        WHEN (price <= 600 AND daily_rate_limit = 0.005) OR
             (price > 600 AND price <= 5000 AND daily_rate_limit = 0.010) OR
             (price > 5000 AND price <= 10000 AND daily_rate_limit = 0.0125) OR
             (price > 10000 AND price <= 30000 AND daily_rate_limit = 0.015) OR
             (price > 30000 AND price <= 50000 AND daily_rate_limit = 0.0175) OR
             (price > 50000 AND daily_rate_limit = 0.020)
        THEN '✅'
        ELSE '❌'
    END as status,
    id
FROM nfts
WHERE is_active = true
ORDER BY price, name;

-- 9. 全NFTの詳細情報（非アクティブも含む）
SELECT 
    '📋 全NFT詳細（非アクティブ含む）' as section,
    ROW_NUMBER() OVER (ORDER BY is_active DESC, price, name) as no,
    name,
    price,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate,
    is_special,
    is_active,
    description,
    SUBSTRING(image_url, 1, 50) || '...' as image_preview,
    created_at::date as created,
    updated_at::date as updated
FROM nfts
ORDER BY is_active DESC, price, name;

-- 10. 修正が必要なNFTの詳細
SELECT 
    '🔧 修正が必要なNFT詳細' as section,
    name,
    price,
    daily_rate_limit as current_limit,
    (daily_rate_limit * 100) || '%' as current_rate,
    CASE 
        WHEN price <= 600 THEN 0.005
        WHEN price <= 5000 THEN 0.010
        WHEN price <= 10000 THEN 0.0125
        WHEN price <= 30000 THEN 0.015
        WHEN price <= 50000 THEN 0.0175
        ELSE 0.020
    END as correct_limit,
    CASE 
        WHEN price <= 600 THEN '0.5%'
        WHEN price <= 5000 THEN '1.0%'
        WHEN price <= 10000 THEN '1.25%'
        WHEN price <= 30000 THEN '1.5%'
        WHEN price <= 50000 THEN '1.75%'
        ELSE '2.0%'
    END as correct_rate,
    'UPDATE nfts SET daily_rate_limit = ' || 
    CASE 
        WHEN price <= 600 THEN '0.005'
        WHEN price <= 5000 THEN '0.010'
        WHEN price <= 10000 THEN '0.0125'
        WHEN price <= 30000 THEN '0.015'
        WHEN price <= 50000 THEN '0.0175'
        ELSE '0.020'
    END || ' WHERE id = ''' || id || ''';' as update_sql
FROM nfts
WHERE is_active = true
AND NOT (
    (price <= 600 AND daily_rate_limit = 0.005) OR
    (price > 600 AND price <= 5000 AND daily_rate_limit = 0.010) OR
    (price > 5000 AND price <= 10000 AND daily_rate_limit = 0.0125) OR
    (price > 10000 AND price <= 30000 AND daily_rate_limit = 0.015) OR
    (price > 30000 AND price <= 50000 AND daily_rate_limit = 0.0175) OR
    (price > 50000 AND daily_rate_limit = 0.020)
)
ORDER BY price;
