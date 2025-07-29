-- 全NFTの日利上限を正しく修正

-- 1. 修正前の状況確認
SELECT 
    '🔍 修正前の状況' as status,
    COUNT(*) as total_nfts,
    COUNT(DISTINCT daily_rate_limit) as unique_rates,
    STRING_AGG(DISTINCT (daily_rate_limit * 100) || '%', ', ' ORDER BY (daily_rate_limit * 100) || '%') as current_rates
FROM nfts
WHERE is_active = true;

-- 2. 修正が必要なNFTの一覧表示
SELECT 
    '❌ 修正が必要なNFT' as section,
    name,
    price,
    daily_rate_limit as current_limit,
    CASE 
        WHEN price <= 600 THEN 0.005
        WHEN price <= 5000 THEN 0.010
        WHEN price <= 10000 THEN 0.0125
        WHEN price <= 30000 THEN 0.015
        WHEN price <= 50000 THEN 0.0175
        ELSE 0.020
    END as correct_limit
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

-- 3. 全NFTの日利上限を価格帯に基づいて修正
DO $$
DECLARE
    update_count INTEGER := 0;
    debug_msg TEXT;
BEGIN
    debug_msg := '🚀 全NFTの日利上限修正を開始';
    RAISE NOTICE '%', debug_msg;
    
    -- $600以下のNFTを0.5%に設定
    UPDATE nfts 
    SET daily_rate_limit = 0.005, updated_at = NOW()
    WHERE is_active = true AND price <= 600 AND daily_rate_limit != 0.005;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ $600以下のNFT: ' || update_count || '件を0.5%に修正';
    RAISE NOTICE '%', debug_msg;
    
    -- $601-5000のNFTを1.0%に設定
    UPDATE nfts 
    SET daily_rate_limit = 0.010, updated_at = NOW()
    WHERE is_active = true AND price > 600 AND price <= 5000 AND daily_rate_limit != 0.010;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ $601-5000のNFT: ' || update_count || '件を1.0%に修正';
    RAISE NOTICE '%', debug_msg;
    
    -- $5001-10000のNFTを1.25%に設定
    UPDATE nfts 
    SET daily_rate_limit = 0.0125, updated_at = NOW()
    WHERE is_active = true AND price > 5000 AND price <= 10000 AND daily_rate_limit != 0.0125;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ $5001-10000のNFT: ' || update_count || '件を1.25%に修正';
    RAISE NOTICE '%', debug_msg;
    
    -- $10001-30000のNFTを1.5%に設定
    UPDATE nfts 
    SET daily_rate_limit = 0.015, updated_at = NOW()
    WHERE is_active = true AND price > 10000 AND price <= 30000 AND daily_rate_limit != 0.015;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ $10001-30000のNFT: ' || update_count || '件を1.5%に修正';
    RAISE NOTICE '%', debug_msg;
    
    -- $30001-50000のNFTを1.75%に設定
    UPDATE nfts 
    SET daily_rate_limit = 0.0175, updated_at = NOW()
    WHERE is_active = true AND price > 30000 AND price <= 50000 AND daily_rate_limit != 0.0175;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ $30001-50000のNFT: ' || update_count || '件を1.75%に修正';
    RAISE NOTICE '%', debug_msg;
    
    -- $50001以上のNFTを2.0%に設定
    UPDATE nfts 
    SET daily_rate_limit = 0.020, updated_at = NOW()
    WHERE is_active = true AND price > 50000 AND daily_rate_limit != 0.020;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ $50001以上のNFT: ' || update_count || '件を2.0%に修正';
    RAISE NOTICE '%', debug_msg;
    
    debug_msg := '🎯 全NFTの日利上限修正完了';
    RAISE NOTICE '%', debug_msg;
END $$;

-- 4. 修正後の確認
SELECT 
    '✅ 修正後の確認' as status,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    COUNT(*) as nft_count,
    MIN(price) as min_price,
    MAX(price) as max_price,
    STRING_AGG(name, ', ' ORDER BY price) as nft_names
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;

-- 5. 価格帯別の分類結果
SELECT 
    '📊 価格帯別分類結果' as result,
    CASE 
        WHEN price <= 600 THEN '1. $0-600 (0.5%)'
        WHEN price <= 5000 THEN '2. $601-5000 (1.0%)'
        WHEN price <= 10000 THEN '3. $5001-10000 (1.25%)'
        WHEN price <= 30000 THEN '4. $10001-30000 (1.5%)'
        WHEN price <= 50000 THEN '5. $30001-50000 (1.75%)'
        ELSE '6. $50001+ (2.0%)'
    END as price_group,
    COUNT(*) as nft_count,
    (daily_rate_limit * 100) || '%' as actual_rate,
    STRING_AGG(name || '($' || price || ')', ', ' ORDER BY price) as nft_list
FROM nfts
WHERE is_active = true
GROUP BY 
    CASE 
        WHEN price <= 600 THEN '1. $0-600 (0.5%)'
        WHEN price <= 5000 THEN '2. $601-5000 (1.0%)'
        WHEN price <= 10000 THEN '3. $5001-10000 (1.25%)'
        WHEN price <= 30000 THEN '4. $10001-30000 (1.5%)'
        WHEN price <= 50000 THEN '5. $30001-50000 (1.75%)'
        ELSE '6. $50001+ (2.0%)'
    END,
    daily_rate_limit
ORDER BY 
    CASE 
        WHEN price <= 600 THEN '1. $0-600 (0.5%)'
        WHEN price <= 5000 THEN '2. $601-5000 (1.0%)'
        WHEN price <= 10000 THEN '3. $5001-10000 (1.25%)'
        WHEN price <= 30000 THEN '4. $10001-30000 (1.5%)'
        WHEN price <= 50000 THEN '5. $30001-50000 (1.75%)'
        ELSE '6. $50001+ (2.0%)'
    END;

-- 6. 全28個のNFTの最終確認
SELECT 
    '🎯 全28個のNFT最終確認' as final_check,
    ROW_NUMBER() OVER (ORDER BY price, name) as no,
    name,
    '$' || price as price,
    (daily_rate_limit * 100) || '%' as rate,
    CASE WHEN is_special THEN '特別' ELSE '通常' END as type,
    CASE 
        WHEN (price <= 600 AND daily_rate_limit = 0.005) OR
             (price > 600 AND price <= 5000 AND daily_rate_limit = 0.010) OR
             (price > 5000 AND price <= 10000 AND daily_rate_limit = 0.0125) OR
             (price > 10000 AND price <= 30000 AND daily_rate_limit = 0.015) OR
             (price > 30000 AND price <= 50000 AND daily_rate_limit = 0.0175) OR
             (price > 50000 AND daily_rate_limit = 0.020)
        THEN '✅ 正常'
        ELSE '❌ 異常'
    END as status
FROM nfts
WHERE is_active = true
ORDER BY price, name;

-- 7. 統計サマリー
SELECT 
    '📈 修正後統計' as summary,
    COUNT(*) as total_nfts,
    COUNT(DISTINCT daily_rate_limit) as unique_rates,
    MIN(price) as min_price,
    MAX(price) as max_price,
    COUNT(CASE WHEN daily_rate_limit = 0.005 THEN 1 END) as rate_05_count,
    COUNT(CASE WHEN daily_rate_limit = 0.010 THEN 1 END) as rate_10_count,
    COUNT(CASE WHEN daily_rate_limit = 0.0125 THEN 1 END) as rate_125_count,
    COUNT(CASE WHEN daily_rate_limit = 0.015 THEN 1 END) as rate_15_count,
    COUNT(CASE WHEN daily_rate_limit = 0.0175 THEN 1 END) as rate_175_count,
    COUNT(CASE WHEN daily_rate_limit = 0.020 THEN 1 END) as rate_20_count
FROM nfts
WHERE is_active = true;

-- 8. 問題があるNFTの確認（修正後にエラーがないかチェック）
SELECT 
    '🔍 問題チェック' as error_check,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ 全NFTが正しく分類されました'
        ELSE '❌ まだ問題があります: ' || COUNT(*) || '件'
    END as result
FROM nfts
WHERE is_active = true
AND NOT (
    (price <= 600 AND daily_rate_limit = 0.005) OR
    (price > 600 AND price <= 5000 AND daily_rate_limit = 0.010) OR
    (price > 5000 AND price <= 10000 AND daily_rate_limit = 0.0125) OR
    (price > 10000 AND price <= 30000 AND daily_rate_limit = 0.015) OR
    (price > 30000 AND price <= 50000 AND daily_rate_limit = 0.0175) OR
    (price > 50000 AND daily_rate_limit = 0.020)
);
