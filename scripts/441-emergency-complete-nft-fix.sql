-- 全NFTの日利上限を仕様書通りに完全修正

DO $$
DECLARE
    debug_msg TEXT;
    update_count INTEGER;
    total_updates INTEGER := 0;
    nft_record RECORD;
BEGIN
    debug_msg := '🚨 緊急NFT完全修正開始';
    RAISE NOTICE '%', debug_msg;
    
    -- 現在の状況を詳細確認
    debug_msg := '🔍 修正前の状況:';
    RAISE NOTICE '%', debug_msg;
    
    FOR nft_record IN 
        SELECT name, price, is_special, daily_rate_limit, (daily_rate_limit * 100) as rate_percent
        FROM nfts 
        WHERE is_active = true
        ORDER BY price, is_special
    LOOP
        debug_msg := '  ' || nft_record.name || ' | $' || nft_record.price || ' | 特別:' || nft_record.is_special || ' | 現在:' || nft_record.rate_percent || '%';
        RAISE NOTICE '%', debug_msg;
    END LOOP;
    
    -- 1. 0.5%グループ: $100, $200, $600の特別NFT
    UPDATE nfts 
    SET daily_rate_limit = 0.005, updated_at = NOW()
    WHERE price IN (100, 200, 600) 
    AND is_active = true 
    AND is_special = true;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ $100,$200,$600特別NFT → 0.5%: ' || update_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    -- 2. 0.5%グループ: $300, $500の通常NFT
    UPDATE nfts 
    SET daily_rate_limit = 0.005, updated_at = NOW()
    WHERE price IN (300, 500) 
    AND is_active = true 
    AND is_special = false;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ $300,$500通常NFT → 0.5%: ' || update_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    -- 3. 1.0%グループ: $1000, $3000, $5000の通常NFT
    UPDATE nfts 
    SET daily_rate_limit = 0.010, updated_at = NOW()
    WHERE price IN (1000, 3000, 5000) 
    AND is_active = true 
    AND is_special = false;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ $1000,$3000,$5000通常NFT → 1.0%: ' || update_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    -- 4. 1.0%グループ: $1100-$8000の特別NFT（$1000特別NFTは除外）
    UPDATE nfts 
    SET daily_rate_limit = 0.010, updated_at = NOW()
    WHERE price >= 1100 AND price <= 8000
    AND is_active = true 
    AND is_special = true;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ $1100-$8000特別NFT → 1.0%: ' || update_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    -- 5. 1.25%グループ: $10000の通常NFT
    UPDATE nfts 
    SET daily_rate_limit = 0.0125, updated_at = NOW()
    WHERE price = 10000 
    AND is_active = true 
    AND is_special = false;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ $10000通常NFT → 1.25%: ' || update_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    -- 6. 1.25%グループ: $1000の特別NFT（重要！）
    UPDATE nfts 
    SET daily_rate_limit = 0.0125, updated_at = NOW()
    WHERE price = 1000 
    AND is_active = true 
    AND is_special = true;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ $1000特別NFT → 1.25%: ' || update_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    -- 7. 1.5%グループ: $30000の通常NFT
    UPDATE nfts 
    SET daily_rate_limit = 0.015, updated_at = NOW()
    WHERE price = 30000 
    AND is_active = true 
    AND is_special = false;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ $30000通常NFT → 1.5%: ' || update_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    -- 8. 1.75%グループ: $50000の通常NFT
    UPDATE nfts 
    SET daily_rate_limit = 0.0175, updated_at = NOW()
    WHERE price = 50000 
    AND is_active = true 
    AND is_special = false;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ $50000通常NFT → 1.75%: ' || update_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    -- 9. 2.0%グループ: $100000の通常NFT
    UPDATE nfts 
    SET daily_rate_limit = 0.020, updated_at = NOW()
    WHERE price = 100000 
    AND is_active = true 
    AND is_special = false;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ $100000通常NFT → 2.0%: ' || update_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    debug_msg := '🎯 全NFT修正完了: 合計 ' || total_updates || '件更新';
    RAISE NOTICE '%', debug_msg;
    
    -- 修正後の状況を詳細確認
    debug_msg := '🔍 修正後の状況:';
    RAISE NOTICE '%', debug_msg;
    
    FOR nft_record IN 
        SELECT name, price, is_special, daily_rate_limit, (daily_rate_limit * 100) as rate_percent
        FROM nfts 
        WHERE is_active = true
        ORDER BY daily_rate_limit, price, is_special
    LOOP
        debug_msg := '  ' || nft_record.name || ' | $' || nft_record.price || ' | 特別:' || nft_record.is_special || ' | 新:' || nft_record.rate_percent || '%';
        RAISE NOTICE '%', debug_msg;
    END LOOP;
END $$;

-- 修正結果の詳細確認
SELECT 
    '📊 NFT分類修正結果詳細' as section,
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

-- 特に重要なNFTの個別確認
SELECT 
    '🎯 重要NFT個別確認' as section,
    name,
    price,
    is_special,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    CASE 
        WHEN name = 'SHOGUN NFT 1000 (Special)' AND daily_rate_limit = 0.0125 THEN '✅ 完璧！1.25%'
        WHEN name = 'SHOGUN NFT 1000' AND daily_rate_limit = 0.010 THEN '✅ 正しい！1.0%'
        WHEN name = 'SHOGUN NFT 10000' AND daily_rate_limit = 0.0125 THEN '✅ 正しい！1.25%'
        WHEN name = 'SHOGUN NFT 30000' AND daily_rate_limit = 0.015 THEN '✅ 正しい！1.5%'
        WHEN name = 'SHOGUN NFT 100000' AND daily_rate_limit = 0.020 THEN '✅ 正しい！2.0%'
        WHEN name IN ('SHOGUN NFT 300', 'SHOGUN NFT 500') AND daily_rate_limit = 0.005 THEN '✅ 正しい！0.5%'
        WHEN name IN ('SHOGUN NFT 100', 'SHOGUN NFT 200', 'SHOGUN NFT 600') AND daily_rate_limit = 0.005 THEN '✅ 正しい！0.5%'
        ELSE '❌ まだ問題: ' || (daily_rate_limit * 100) || '%'
    END as status
FROM nfts
WHERE is_active = true
AND (
    name LIKE '%1000%' OR 
    name LIKE '%10000%' OR 
    name LIKE '%30000%' OR 
    name LIKE '%100000%' OR
    name IN ('SHOGUN NFT 300', 'SHOGUN NFT 500', 'SHOGUN NFT 100', 'SHOGUN NFT 200', 'SHOGUN NFT 600')
)
ORDER BY price, is_special DESC;
