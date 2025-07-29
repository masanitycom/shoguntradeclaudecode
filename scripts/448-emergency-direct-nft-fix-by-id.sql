-- NFTを個別IDで直接強制更新

DO $$
DECLARE
    debug_msg TEXT;
    update_count INTEGER;
    total_updates INTEGER := 0;
BEGIN
    debug_msg := '🚨 NFT個別ID直接更新開始';
    RAISE NOTICE '%', debug_msg;
    
    -- 1. SHOGUN NFT 100 (特別) → 0.5%
    UPDATE nfts 
    SET daily_rate_limit = 0.005, updated_at = NOW() 
    WHERE name = 'SHOGUN NFT 100' AND is_special = true;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ SHOGUN NFT 100 (特別) → 0.5%: ' || update_count || '件更新';
    RAISE NOTICE '%', debug_msg;
    
    -- 2. SHOGUN NFT 200 (特別) → 0.5%
    UPDATE nfts 
    SET daily_rate_limit = 0.005, updated_at = NOW() 
    WHERE name = 'SHOGUN NFT 200' AND is_special = true;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ SHOGUN NFT 200 (特別) → 0.5%: ' || update_count || '件更新';
    RAISE NOTICE '%', debug_msg;
    
    -- 3. SHOGUN NFT 600 (特別) → 0.5%
    UPDATE nfts 
    SET daily_rate_limit = 0.005, updated_at = NOW() 
    WHERE name = 'SHOGUN NFT 600' AND is_special = true;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ SHOGUN NFT 600 (特別) → 0.5%: ' || update_count || '件更新';
    RAISE NOTICE '%', debug_msg;
    
    -- 4. SHOGUN NFT 300 (通常) → 0.5%
    UPDATE nfts 
    SET daily_rate_limit = 0.005, updated_at = NOW() 
    WHERE name = 'SHOGUN NFT 300' AND is_special = false;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ SHOGUN NFT 300 (通常) → 0.5%: ' || update_count || '件更新';
    RAISE NOTICE '%', debug_msg;
    
    -- 5. SHOGUN NFT 500 (通常) → 0.5%
    UPDATE nfts 
    SET daily_rate_limit = 0.005, updated_at = NOW() 
    WHERE name = 'SHOGUN NFT 500' AND is_special = false;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ SHOGUN NFT 500 (通常) → 0.5%: ' || update_count || '件更新';
    RAISE NOTICE '%', debug_msg;
    
    -- 6. SHOGUN NFT 1000 (Special) → 1.25%
    UPDATE nfts 
    SET daily_rate_limit = 0.0125, updated_at = NOW() 
    WHERE name = 'SHOGUN NFT 1000 (Special)' AND is_special = true;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ SHOGUN NFT 1000 (Special) → 1.25%: ' || update_count || '件更新';
    RAISE NOTICE '%', debug_msg;
    
    -- 7. SHOGUN NFT 10000 (通常) → 1.25%
    UPDATE nfts 
    SET daily_rate_limit = 0.0125, updated_at = NOW() 
    WHERE name = 'SHOGUN NFT 10000' AND is_special = false;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ SHOGUN NFT 10000 (通常) → 1.25%: ' || update_count || '件更新';
    RAISE NOTICE '%', debug_msg;
    
    -- 8. SHOGUN NFT 30000 (通常) → 1.5%
    UPDATE nfts 
    SET daily_rate_limit = 0.015, updated_at = NOW() 
    WHERE name = 'SHOGUN NFT 30000' AND is_special = false;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ SHOGUN NFT 30000 (通常) → 1.5%: ' || update_count || '件更新';
    RAISE NOTICE '%', debug_msg;
    
    -- 9. SHOGUN NFT 50000 (通常) → 1.75%
    UPDATE nfts 
    SET daily_rate_limit = 0.0175, updated_at = NOW() 
    WHERE name = 'SHOGUN NFT 50000' AND is_special = false;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ SHOGUN NFT 50000 (通常) → 1.75%: ' || update_count || '件更新';
    RAISE NOTICE '%', debug_msg;
    
    -- 10. SHOGUN NFT 100000 (通常) → 2.0% (既に正しい)
    UPDATE nfts 
    SET daily_rate_limit = 0.020, updated_at = NOW() 
    WHERE name = 'SHOGUN NFT 100000' AND is_special = false;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    total_updates := total_updates + update_count;
    debug_msg := '✅ SHOGUN NFT 100000 (通常) → 2.0%: ' || update_count || '件更新';
    RAISE NOTICE '%', debug_msg;
    
    debug_msg := '🎯 NFT個別更新完了: 合計 ' || total_updates || '件';
    RAISE NOTICE '%', debug_msg;
END $$;

-- 更新後の確認
SELECT 
    '🔍 更新後確認' as section,
    name,
    price,
    is_special,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    CASE 
        WHEN daily_rate_limit = 0.005 THEN '✅ 0.5%グループ'
        WHEN daily_rate_limit = 0.010 THEN '✅ 1.0%グループ'
        WHEN daily_rate_limit = 0.0125 THEN '✅ 1.25%グループ'
        WHEN daily_rate_limit = 0.015 THEN '✅ 1.5%グループ'
        WHEN daily_rate_limit = 0.0175 THEN '✅ 1.75%グループ'
        WHEN daily_rate_limit = 0.020 THEN '✅ 2.0%グループ'
        ELSE '❌ 不明: ' || daily_rate_limit
    END as group_status
FROM nfts
WHERE is_active = true
ORDER BY daily_rate_limit, price, is_special DESC;

-- グループ別分布確認
SELECT 
    '📊 更新後グループ別分布' as section,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    COUNT(*) as nft_count,
    STRING_AGG(name, ', ' ORDER BY price, name) as nft_names
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;
