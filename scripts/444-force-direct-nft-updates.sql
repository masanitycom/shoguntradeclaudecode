-- NFTの日利上限を直接的に強制更新

DO $$
DECLARE
    debug_msg TEXT;
    nft_id UUID;
    update_count INTEGER;
    total_updates INTEGER := 0;
BEGIN
    debug_msg := '🚨 NFT直接強制更新開始';
    RAISE NOTICE '%', debug_msg;
    
    -- 1. SHOGUN NFT 100 (特別) → 0.5%
    SELECT id INTO nft_id FROM nfts WHERE name = 'SHOGUN NFT 100' AND is_special = true LIMIT 1;
    IF nft_id IS NOT NULL THEN
        UPDATE nfts SET daily_rate_limit = 0.005, updated_at = NOW() WHERE id = nft_id;
        GET DIAGNOSTICS update_count = ROW_COUNT;
        total_updates := total_updates + update_count;
        debug_msg := '✅ SHOGUN NFT 100 (特別) → 0.5%: ' || update_count || '件';
        RAISE NOTICE '%', debug_msg;
    END IF;
    
    -- 2. SHOGUN NFT 200 (特別) → 0.5%
    SELECT id INTO nft_id FROM nfts WHERE name = 'SHOGUN NFT 200' AND is_special = true LIMIT 1;
    IF nft_id IS NOT NULL THEN
        UPDATE nfts SET daily_rate_limit = 0.005, updated_at = NOW() WHERE id = nft_id;
        GET DIAGNOSTICS update_count = ROW_COUNT;
        total_updates := total_updates + update_count;
        debug_msg := '✅ SHOGUN NFT 200 (特別) → 0.5%: ' || update_count || '件';
        RAISE NOTICE '%', debug_msg;
    END IF;
    
    -- 3. SHOGUN NFT 600 (特別) → 0.5%
    SELECT id INTO nft_id FROM nfts WHERE name = 'SHOGUN NFT 600' AND is_special = true LIMIT 1;
    IF nft_id IS NOT NULL THEN
        UPDATE nfts SET daily_rate_limit = 0.005, updated_at = NOW() WHERE id = nft_id;
        GET DIAGNOSTICS update_count = ROW_COUNT;
        total_updates := total_updates + update_count;
        debug_msg := '✅ SHOGUN NFT 600 (特別) → 0.5%: ' || update_count || '件';
        RAISE NOTICE '%', debug_msg;
    END IF;
    
    -- 4. SHOGUN NFT 300 (通常) → 0.5%
    SELECT id INTO nft_id FROM nfts WHERE name = 'SHOGUN NFT 300' AND is_special = false LIMIT 1;
    IF nft_id IS NOT NULL THEN
        UPDATE nfts SET daily_rate_limit = 0.005, updated_at = NOW() WHERE id = nft_id;
        GET DIAGNOSTICS update_count = ROW_COUNT;
        total_updates := total_updates + update_count;
        debug_msg := '✅ SHOGUN NFT 300 (通常) → 0.5%: ' || update_count || '件';
        RAISE NOTICE '%', debug_msg;
    END IF;
    
    -- 5. SHOGUN NFT 500 (通常) → 0.5%
    SELECT id INTO nft_id FROM nfts WHERE name = 'SHOGUN NFT 500' AND is_special = false LIMIT 1;
    IF nft_id IS NOT NULL THEN
        UPDATE nfts SET daily_rate_limit = 0.005, updated_at = NOW() WHERE id = nft_id;
        GET DIAGNOSTICS update_count = ROW_COUNT;
        total_updates := total_updates + update_count;
        debug_msg := '✅ SHOGUN NFT 500 (通常) → 0.5%: ' || update_count || '件';
        RAISE NOTICE '%', debug_msg;
    END IF;
    
    -- 6. SHOGUN NFT 1000 (Special) → 1.25%
    SELECT id INTO nft_id FROM nfts WHERE name = 'SHOGUN NFT 1000 (Special)' AND is_special = true LIMIT 1;
    IF nft_id IS NOT NULL THEN
        UPDATE nfts SET daily_rate_limit = 0.0125, updated_at = NOW() WHERE id = nft_id;
        GET DIAGNOSTICS update_count = ROW_COUNT;
        total_updates := total_updates + update_count;
        debug_msg := '✅ SHOGUN NFT 1000 (Special) → 1.25%: ' || update_count || '件';
        RAISE NOTICE '%', debug_msg;
    END IF;
    
    -- 7. SHOGUN NFT 10000 (通常) → 1.25%
    SELECT id INTO nft_id FROM nfts WHERE name = 'SHOGUN NFT 10000' AND is_special = false LIMIT 1;
    IF nft_id IS NOT NULL THEN
        UPDATE nfts SET daily_rate_limit = 0.0125, updated_at = NOW() WHERE id = nft_id;
        GET DIAGNOSTICS update_count = ROW_COUNT;
        total_updates := total_updates + update_count;
        debug_msg := '✅ SHOGUN NFT 10000 (通常) → 1.25%: ' || update_count || '件';
        RAISE NOTICE '%', debug_msg;
    END IF;
    
    -- 8. SHOGUN NFT 30000 (通常) → 1.5%
    SELECT id INTO nft_id FROM nfts WHERE name = 'SHOGUN NFT 30000' AND is_special = false LIMIT 1;
    IF nft_id IS NOT NULL THEN
        UPDATE nfts SET daily_rate_limit = 0.015, updated_at = NOW() WHERE id = nft_id;
        GET DIAGNOSTICS update_count = ROW_COUNT;
        total_updates := total_updates + update_count;
        debug_msg := '✅ SHOGUN NFT 30000 (通常) → 1.5%: ' || update_count || '件';
        RAISE NOTICE '%', debug_msg;
    END IF;
    
    -- 9. SHOGUN NFT 50000 (通常) → 1.75%
    SELECT id INTO nft_id FROM nfts WHERE name = 'SHOGUN NFT 50000' AND is_special = false LIMIT 1;
    IF nft_id IS NOT NULL THEN
        UPDATE nfts SET daily_rate_limit = 0.0175, updated_at = NOW() WHERE id = nft_id;
        GET DIAGNOSTICS update_count = ROW_COUNT;
        total_updates := total_updates + update_count;
        debug_msg := '✅ SHOGUN NFT 50000 (通常) → 1.75%: ' || update_count || '件';
        RAISE NOTICE '%', debug_msg;
    END IF;
    
    -- 10. その他の特別NFT ($1100-$8000) → 1.0%
    UPDATE nfts 
    SET daily_rate_limit = 0.010, updated_at = NOW() 
    WHERE is_special = true 
    AND price >= 1100 AND price <= 8000
    AND name NOT IN ('SHOGUN NFT 1000 (Special)');
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ その他特別NFT ($1100-$8000) → 1.0%: ' || update_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    debug_msg := '🎯 NFT直接強制更新完了: 合計 ' || total_updates || '件';
    RAISE NOTICE '%', debug_msg;
END $$;

-- 更新結果の詳細確認
SELECT 
    '🎯 NFT更新結果詳細確認' as section,
    name,
    price,
    is_special,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    CASE 
        WHEN name = 'SHOGUN NFT 100' AND is_special = true AND daily_rate_limit = 0.005 THEN '✅ 完璧！0.5%'
        WHEN name = 'SHOGUN NFT 200' AND is_special = true AND daily_rate_limit = 0.005 THEN '✅ 完璧！0.5%'
        WHEN name = 'SHOGUN NFT 600' AND is_special = true AND daily_rate_limit = 0.005 THEN '✅ 完璧！0.5%'
        WHEN name = 'SHOGUN NFT 300' AND is_special = false AND daily_rate_limit = 0.005 THEN '✅ 完璧！0.5%'
        WHEN name = 'SHOGUN NFT 500' AND is_special = false AND daily_rate_limit = 0.005 THEN '✅ 完璧！0.5%'
        WHEN name = 'SHOGUN NFT 1000 (Special)' AND daily_rate_limit = 0.0125 THEN '✅ 完璧！1.25%'
        WHEN name = 'SHOGUN NFT 1000' AND daily_rate_limit = 0.010 THEN '✅ 完璧！1.0%'
        WHEN name = 'SHOGUN NFT 10000' AND daily_rate_limit = 0.0125 THEN '✅ 完璧！1.25%'
        WHEN name = 'SHOGUN NFT 30000' AND daily_rate_limit = 0.015 THEN '✅ 完璧！1.5%'
        WHEN name = 'SHOGUN NFT 100000' AND daily_rate_limit = 0.020 THEN '✅ 完璧！2.0%'
        ELSE '❌ まだ問題: ' || (daily_rate_limit * 100) || '%'
    END as status
FROM nfts
WHERE is_active = true
ORDER BY daily_rate_limit, price, is_special DESC;

-- グループ別分布の最終確認
SELECT 
    '📊 グループ別分布最終確認' as section,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    COUNT(*) as nft_count,
    STRING_AGG(name, ', ' ORDER BY price, name) as nft_names
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;
