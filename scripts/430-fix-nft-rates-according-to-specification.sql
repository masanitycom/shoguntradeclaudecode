-- 仕様書に基づいてNFTの日利上限を正しく修正

DO $$
DECLARE
    update_count INTEGER := 0;
    debug_msg TEXT;
BEGIN
    debug_msg := '🚀 仕様書に基づくNFT日利上限修正を開始';
    RAISE NOTICE '%', debug_msg;
    
    -- 通常NFT（is_special: false）の修正
    -- SHOGUN NFT 300: 0.5%
    UPDATE nfts 
    SET daily_rate_limit = 0.005, updated_at = NOW()
    WHERE is_active = true AND is_special = false AND price = 300 AND daily_rate_limit != 0.005;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ SHOGUN NFT 300 (通常): ' || update_count || '件を0.5%に修正';
    RAISE NOTICE '%', debug_msg;
    
    -- SHOGUN NFT 500: 0.5%
    UPDATE nfts 
    SET daily_rate_limit = 0.005, updated_at = NOW()
    WHERE is_active = true AND is_special = false AND price = 500 AND daily_rate_limit != 0.005;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ SHOGUN NFT 500 (通常): ' || update_count || '件を0.5%に修正';
    RAISE NOTICE '%', debug_msg;
    
    -- SHOGUN NFT 1000 (通常): 1.0%
    UPDATE nfts 
    SET daily_rate_limit = 0.010, updated_at = NOW()
    WHERE is_active = true AND is_special = false AND price = 1000 AND daily_rate_limit != 0.010;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ SHOGUN NFT 1000 (通常): ' || update_count || '件を1.0%に修正';
    RAISE NOTICE '%', debug_msg;
    
    -- SHOGUN NFT 3000: 1.0%
    UPDATE nfts 
    SET daily_rate_limit = 0.010, updated_at = NOW()
    WHERE is_active = true AND is_special = false AND price = 3000 AND daily_rate_limit != 0.010;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ SHOGUN NFT 3000 (通常): ' || update_count || '件を1.0%に修正';
    RAISE NOTICE '%', debug_msg;
    
    -- SHOGUN NFT 5000: 1.0%
    UPDATE nfts 
    SET daily_rate_limit = 0.010, updated_at = NOW()
    WHERE is_active = true AND is_special = false AND price = 5000 AND daily_rate_limit != 0.010;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ SHOGUN NFT 5000 (通常): ' || update_count || '件を1.0%に修正';
    RAISE NOTICE '%', debug_msg;
    
    -- SHOGUN NFT 10000: 1.25%
    UPDATE nfts 
    SET daily_rate_limit = 0.0125, updated_at = NOW()
    WHERE is_active = true AND is_special = false AND price = 10000 AND daily_rate_limit != 0.0125;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ SHOGUN NFT 10000 (通常): ' || update_count || '件を1.25%に修正';
    RAISE NOTICE '%', debug_msg;
    
    -- SHOGUN NFT 30000: 1.5%
    UPDATE nfts 
    SET daily_rate_limit = 0.015, updated_at = NOW()
    WHERE is_active = true AND is_special = false AND price = 30000 AND daily_rate_limit != 0.015;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ SHOGUN NFT 30000 (通常): ' || update_count || '件を1.5%に修正';
    RAISE NOTICE '%', debug_msg;
    
    -- SHOGUN NFT 50000: 1.75% (新規追加)
    UPDATE nfts 
    SET daily_rate_limit = 0.0175, updated_at = NOW()
    WHERE is_active = true AND is_special = false AND price = 50000 AND daily_rate_limit != 0.0175;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ SHOGUN NFT 50000 (通常): ' || update_count || '件を1.75%に修正';
    RAISE NOTICE '%', debug_msg;
    
    -- SHOGUN NFT 100000: 2.0%
    UPDATE nfts 
    SET daily_rate_limit = 0.020, updated_at = NOW()
    WHERE is_active = true AND is_special = false AND price = 100000 AND daily_rate_limit != 0.020;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ SHOGUN NFT 100000 (通常): ' || update_count || '件を2.0%に修正';
    RAISE NOTICE '%', debug_msg;
    
    -- 特別NFT（is_special: true）の修正
    -- $100, $200, $600: 0.5%
    UPDATE nfts 
    SET daily_rate_limit = 0.005, updated_at = NOW()
    WHERE is_active = true AND is_special = true AND price IN (100, 200, 600) AND daily_rate_limit != 0.005;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ 特別NFT $100-600: ' || update_count || '件を0.5%に修正';
    RAISE NOTICE '%', debug_msg;
    
    -- 特別NFT SHOGUN NFT 1000: 1.25%
    UPDATE nfts 
    SET daily_rate_limit = 0.0125, updated_at = NOW()
    WHERE is_active = true AND is_special = true AND price = 1000 AND daily_rate_limit != 0.0125;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ SHOGUN NFT 1000 (特別): ' || update_count || '件を1.25%に修正';
    RAISE NOTICE '%', debug_msg;
    
    -- その他特別NFT $1100-8000: 1.0%
    UPDATE nfts 
    SET daily_rate_limit = 0.010, updated_at = NOW()
    WHERE is_active = true AND is_special = true 
    AND price IN (1100, 1177, 1217, 1227, 1300, 1350, 1500, 1600, 1836, 2000, 2100, 3175, 4000, 6600, 8000) 
    AND daily_rate_limit != 0.010;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ その他特別NFT $1100-8000: ' || update_count || '件を1.0%に修正';
    RAISE NOTICE '%', debug_msg;
    
    debug_msg := '🎯 仕様書に基づく修正完了';
    RAISE NOTICE '%', debug_msg;
END $$;

-- 修正後の確認
SELECT 
    '✅ 修正後の確認' as status,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    COUNT(*) as nft_count,
    STRING_AGG(name || '($' || price || ')' || CASE WHEN is_special THEN '[特別]' ELSE '[通常]' END, ', ' ORDER BY price) as nft_list
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;

-- SHOGUN NFT 1000の特別確認
SELECT 
    '🔍 SHOGUN NFT 1000の確認' as section,
    name,
    price,
    is_special,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    CASE 
        WHEN is_special = true THEN '特別NFT: 1.25%が正しい'
        WHEN is_special = false THEN '通常NFT: 1.0%が正しい'
    END as correct_setting
FROM nfts
WHERE is_active = true AND price = 1000
ORDER BY is_special;
