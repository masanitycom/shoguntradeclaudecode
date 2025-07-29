-- NFTを直接ID指定で強制更新

DO $$
DECLARE
    update_count INTEGER := 0;
    debug_msg TEXT;
BEGIN
    debug_msg := '🚀 NFT直接更新開始';
    RAISE NOTICE '%', debug_msg;
    
    -- 0.5%グループ (特別NFT: 100, 200, 600)
    UPDATE nfts SET 
        daily_rate_limit = 0.005,
        updated_at = CURRENT_TIMESTAMP
    WHERE name IN ('SHOGUN NFT 100', 'SHOGUN NFT 200', 'SHOGUN NFT 600') 
    AND is_special = true 
    AND is_active = true;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ 0.5%グループ(特別): ' || update_count || '件更新';
    RAISE NOTICE '%', debug_msg;
    
    -- 0.5%グループ (通常NFT: 300, 500)
    UPDATE nfts SET 
        daily_rate_limit = 0.005,
        updated_at = CURRENT_TIMESTAMP
    WHERE name IN ('SHOGUN NFT 300', 'SHOGUN NFT 500') 
    AND is_special = false 
    AND is_active = true;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ 0.5%グループ(通常): ' || update_count || '件更新';
    RAISE NOTICE '%', debug_msg;
    
    -- 1.25%グループ (特別NFT: 1000 Special)
    UPDATE nfts SET 
        daily_rate_limit = 0.0125,
        updated_at = CURRENT_TIMESTAMP
    WHERE name = 'SHOGUN NFT 1000 (Special)' 
    AND is_special = true 
    AND is_active = true;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ 1.25%グループ(特別): ' || update_count || '件更新';
    RAISE NOTICE '%', debug_msg;
    
    -- 1.25%グループ (通常NFT: 10000)
    UPDATE nfts SET 
        daily_rate_limit = 0.0125,
        updated_at = CURRENT_TIMESTAMP
    WHERE name = 'SHOGUN NFT 10000' 
    AND is_special = false 
    AND is_active = true;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ 1.25%グループ(通常): ' || update_count || '件更新';
    RAISE NOTICE '%', debug_msg;
    
    -- 1.5%グループ (通常NFT: 30000)
    UPDATE nfts SET 
        daily_rate_limit = 0.015,
        updated_at = CURRENT_TIMESTAMP
    WHERE name = 'SHOGUN NFT 30000' 
    AND is_special = false 
    AND is_active = true;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ 1.5%グループ(通常): ' || update_count || '件更新';
    RAISE NOTICE '%', debug_msg;
    
    -- 1.75%グループ (通常NFT: 50000)
    UPDATE nfts SET 
        daily_rate_limit = 0.0175,
        updated_at = CURRENT_TIMESTAMP
    WHERE name = 'SHOGUN NFT 50000' 
    AND is_special = false 
    AND is_active = true;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ 1.75%グループ(通常): ' || update_count || '件更新';
    RAISE NOTICE '%', debug_msg;
    
    -- 2.0%グループ (通常NFT: 100000)
    UPDATE nfts SET 
        daily_rate_limit = 0.02,
        updated_at = CURRENT_TIMESTAMP
    WHERE name = 'SHOGUN NFT 100000' 
    AND is_special = false 
    AND is_active = true;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ 2.0%グループ(通常): ' || update_count || '件更新';
    RAISE NOTICE '%', debug_msg;
    
    -- 残りのNFTを1.0%に設定
    UPDATE nfts SET 
        daily_rate_limit = 0.01,
        updated_at = CURRENT_TIMESTAMP
    WHERE name NOT IN (
        'SHOGUN NFT 100', 'SHOGUN NFT 200', 'SHOGUN NFT 600', 'SHOGUN NFT 300', 'SHOGUN NFT 500',
        'SHOGUN NFT 1000 (Special)', 'SHOGUN NFT 10000', 'SHOGUN NFT 30000', 'SHOGUN NFT 50000', 'SHOGUN NFT 100000'
    )
    AND is_active = true;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '✅ 1.0%グループ(残り): ' || update_count || '件更新';
    RAISE NOTICE '%', debug_msg;
    
    debug_msg := '🎯 NFT更新完了！';
    RAISE NOTICE '%', debug_msg;
    
END $$;

-- 更新結果を確認
SELECT 
    '📊 更新後グループ別分布' as section,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    COUNT(*) as nft_count,
    STRING_AGG(name, ', ' ORDER BY name) as nft_names
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;

-- 管理画面表示用確認
SELECT 
    '📊 管理画面表示用確認' as section,
    (SELECT COUNT(*) FROM user_nfts WHERE is_active = true) as active_investments,
    (SELECT COUNT(*) FROM nfts WHERE is_active = true) as available_nfts,
    (SELECT COUNT(*) FROM group_weekly_rates WHERE week_start >= DATE_TRUNC('week', CURRENT_DATE)) as current_week_settings,
    (SELECT COUNT(DISTINCT daily_rate_limit) FROM nfts WHERE is_active = true) as total_groups;
