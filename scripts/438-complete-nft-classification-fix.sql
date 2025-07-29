-- 全NFTの分類を仕様書通りに完全修正

DO $$
DECLARE
    debug_msg TEXT;
    update_count INTEGER;
    total_updates INTEGER := 0;
BEGIN
    debug_msg := '🚨 全NFT分類完全修正開始';
    RAISE NOTICE '%', debug_msg;
    
    -- 0.5%グループ: $300, $500の通常NFT
    UPDATE nfts 
    SET daily_rate_limit = 0.005, updated_at = NOW()
    WHERE price IN (300, 500) 
    AND is_active = true 
    AND is_special = false;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ $300-500通常NFT → 0.5%: ' || update_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    -- 0.5%グループ: $100, $200, $600の特別NFT
    UPDATE nfts 
    SET daily_rate_limit = 0.005, updated_at = NOW()
    WHERE price IN (100, 200, 600) 
    AND is_active = true 
    AND is_special = true;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ $100-600特別NFT → 0.5%: ' || update_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    -- 1.0%グループ: $1000, $3000, $5000の通常NFT
    UPDATE nfts 
    SET daily_rate_limit = 0.010, updated_at = NOW()
    WHERE price IN (1000, 3000, 5000) 
    AND is_active = true 
    AND is_special = false;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ $1000-5000通常NFT → 1.0%: ' || update_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    -- 1.0%グループ: $1100-8000の特別NFT
    UPDATE nfts 
    SET daily_rate_limit = 0.010, updated_at = NOW()
    WHERE price >= 1100 AND price <= 8000
    AND is_active = true 
    AND is_special = true
    AND price != 1000; -- $1000特別NFTは除外
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ $1100-8000特別NFT → 1.0%: ' || update_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    -- 1.25%グループ: $10000の通常NFT
    UPDATE nfts 
    SET daily_rate_limit = 0.0125, updated_at = NOW()
    WHERE price = 10000 
    AND is_active = true 
    AND is_special = false;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ $10000通常NFT → 1.25%: ' || update_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    -- 1.25%グループ: $1000の特別NFT（再度確実に）
    UPDATE nfts 
    SET daily_rate_limit = 0.0125, updated_at = NOW()
    WHERE price = 1000 
    AND is_active = true 
    AND is_special = true;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ $1000特別NFT → 1.25%: ' || update_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    -- 1.5%グループ: $30000の通常NFT
    UPDATE nfts 
    SET daily_rate_limit = 0.015, updated_at = NOW()
    WHERE price = 30000 
    AND is_active = true 
    AND is_special = false;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ $30000通常NFT → 1.5%: ' || update_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    -- 1.75%グループ: $50000の通常NFT
    UPDATE nfts 
    SET daily_rate_limit = 0.0175, updated_at = NOW()
    WHERE price = 50000 
    AND is_active = true 
    AND is_special = false;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ $50000通常NFT → 1.75%: ' || update_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    -- 2.0%グループ: $100000の通常NFT
    UPDATE nfts 
    SET daily_rate_limit = 0.020, updated_at = NOW()
    WHERE price = 100000 
    AND is_active = true 
    AND is_special = false;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ $100000通常NFT → 2.0%: ' || update_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    debug_msg := '🎯 全NFT分類修正完了: 合計 ' || total_updates || '件更新';
    RAISE NOTICE '%', debug_msg;
END $$;

-- 修正結果の詳細確認
SELECT 
    '📊 NFT分類修正結果' as section,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    COUNT(*) as nft_count,
    STRING_AGG(
        name || '($' || price || ')' || 
        CASE WHEN is_special THEN '[特別]' ELSE '[通常]' END, 
        ', ' ORDER BY price, name
    ) as nft_list
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;

-- 特に重要なSHOGUN NFT 1000の確認
SELECT 
    '🎯 SHOGUN NFT 1000最終確認' as section,
    name,
    price,
    is_special,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    CASE 
        WHEN name = 'SHOGUN NFT 1000 (Special)' AND daily_rate_limit = 0.0125 THEN '✅ 完璧！'
        WHEN name = 'SHOGUN NFT 1000' AND daily_rate_limit = 0.010 THEN '✅ 正しい'
        ELSE '❌ まだ問題: ' || daily_rate_limit
    END as final_status
FROM nfts
WHERE name LIKE '%1000%' AND is_active = true
ORDER BY is_special DESC;
