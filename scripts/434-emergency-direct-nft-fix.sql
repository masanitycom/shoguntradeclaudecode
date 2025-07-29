-- 緊急：直接的なNFT修正

DO $$
DECLARE
    debug_msg TEXT;
    update_count INTEGER;
BEGIN
    debug_msg := '🚨 緊急NFT修正開始';
    RAISE NOTICE '%', debug_msg;
    
    -- SHOGUN NFT 1000 (Special)を強制的に1.25%に修正
    UPDATE nfts 
    SET daily_rate_limit = 0.0125, updated_at = NOW()
    WHERE name = 'SHOGUN NFT 1000 (Special)' 
    AND is_active = true 
    AND is_special = true;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '🎯 SHOGUN NFT 1000 (Special): ' || update_count || '件を1.25%に強制修正';
    RAISE NOTICE '%', debug_msg;
    
    -- 他の特別NFT 1000も確認して修正
    UPDATE nfts 
    SET daily_rate_limit = 0.0125, updated_at = NOW()
    WHERE price = 1000 
    AND is_active = true 
    AND is_special = true
    AND daily_rate_limit != 0.0125;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '🎯 価格1000の特別NFT: ' || update_count || '件を1.25%に強制修正';
    RAISE NOTICE '%', debug_msg;
    
    -- 0.5%グループのNFTを修正
    -- $300, $500の通常NFT
    UPDATE nfts 
    SET daily_rate_limit = 0.005, updated_at = NOW()
    WHERE price IN (300, 500) 
    AND is_active = true 
    AND is_special = false
    AND daily_rate_limit != 0.005;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '🎯 $300-500通常NFT: ' || update_count || '件を0.5%に修正';
    RAISE NOTICE '%', debug_msg;
    
    -- $100, $200, $600の特別NFT
    UPDATE nfts 
    SET daily_rate_limit = 0.005, updated_at = NOW()
    WHERE price IN (100, 200, 600) 
    AND is_active = true 
    AND is_special = true
    AND daily_rate_limit != 0.005;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '🎯 $100-600特別NFT: ' || update_count || '件を0.5%に修正';
    RAISE NOTICE '%', debug_msg;
    
    -- 1.25%グループのNFT
    -- $10000の通常NFT
    UPDATE nfts 
    SET daily_rate_limit = 0.0125, updated_at = NOW()
    WHERE price = 10000 
    AND is_active = true 
    AND is_special = false
    AND daily_rate_limit != 0.0125;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '🎯 $10000通常NFT: ' || update_count || '件を1.25%に修正';
    RAISE NOTICE '%', debug_msg;
    
    -- 1.5%グループのNFT
    -- $30000の通常NFT
    UPDATE nfts 
    SET daily_rate_limit = 0.015, updated_at = NOW()
    WHERE price = 30000 
    AND is_active = true 
    AND is_special = false
    AND daily_rate_limit != 0.015;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '🎯 $30000通常NFT: ' || update_count || '件を1.5%に修正';
    RAISE NOTICE '%', debug_msg;
    
    -- 2.0%グループのNFT
    -- $100000の通常NFT
    UPDATE nfts 
    SET daily_rate_limit = 0.020, updated_at = NOW()
    WHERE price = 100000 
    AND is_active = true 
    AND is_special = false
    AND daily_rate_limit != 0.020;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '🎯 $100000通常NFT: ' || update_count || '件を2.0%に修正';
    RAISE NOTICE '%', debug_msg;
    
    debug_msg := '✅ 緊急NFT修正完了';
    RAISE NOTICE '%', debug_msg;
END $$;

-- 修正後の確認
SELECT 
    '✅ 緊急修正後の確認' as section,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    COUNT(*) as nft_count,
    STRING_AGG(name || '($' || price || ')' || CASE WHEN is_special THEN '[特別]' ELSE '[通常]' END, ', ') as nft_list
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;

-- SHOGUN NFT 1000の最終確認
SELECT 
    '🎯 SHOGUN NFT 1000最終確認' as section,
    name,
    price,
    is_special,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    CASE 
        WHEN is_special = true AND daily_rate_limit = 0.0125 THEN '✅ 修正成功'
        WHEN is_special = false AND daily_rate_limit = 0.010 THEN '✅ 正しい'
        ELSE '❌ まだ間違っている: ' || daily_rate_limit
    END as final_status
FROM nfts
WHERE is_active = true AND price = 1000
ORDER BY is_special;
