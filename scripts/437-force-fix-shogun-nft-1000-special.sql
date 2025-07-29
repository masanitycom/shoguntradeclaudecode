-- SHOGUN NFT 1000 (Special)を強制的に修正

DO $$
DECLARE
    debug_msg TEXT;
    update_count INTEGER;
    nft_record RECORD;
BEGIN
    debug_msg := '🚨 SHOGUN NFT 1000 (Special) 強制修正開始';
    RAISE NOTICE '%', debug_msg;
    
    -- 現在の状況を確認
    FOR nft_record IN 
        SELECT id, name, price, is_special, daily_rate_limit
        FROM nfts 
        WHERE name LIKE '%1000%' AND is_active = true
        ORDER BY is_special
    LOOP
        debug_msg := '🔍 発見: ' || nft_record.name || ' | 価格: $' || nft_record.price || ' | 特別: ' || nft_record.is_special || ' | 現在の上限: ' || (nft_record.daily_rate_limit * 100) || '%';
        RAISE NOTICE '%', debug_msg;
    END LOOP;
    
    -- SHOGUN NFT 1000 (Special)を直接IDで特定して修正
    UPDATE nfts 
    SET 
        daily_rate_limit = 0.0125,
        updated_at = NOW()
    WHERE 
        name = 'SHOGUN NFT 1000 (Special)'
        AND is_active = true 
        AND is_special = true
        AND price = 1000;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '🎯 名前による修正: ' || update_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    -- 価格と特別フラグで再度修正を試行
    UPDATE nfts 
    SET 
        daily_rate_limit = 0.0125,
        updated_at = NOW()
    WHERE 
        price = 1000
        AND is_active = true 
        AND is_special = true
        AND daily_rate_limit != 0.0125;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '🎯 価格・特別フラグによる修正: ' || update_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    -- 全ての特別NFTで価格1000のものを修正
    UPDATE nfts 
    SET 
        daily_rate_limit = 0.0125,
        updated_at = NOW()
    WHERE 
        price::numeric = 1000
        AND is_special = true
        AND is_active = true;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    debug_msg := '🎯 全特別NFT価格1000修正: ' || update_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    -- 修正後の確認
    FOR nft_record IN 
        SELECT id, name, price, is_special, daily_rate_limit
        FROM nfts 
        WHERE name LIKE '%1000%' AND is_active = true
        ORDER BY is_special
    LOOP
        debug_msg := '✅ 修正後: ' || nft_record.name || ' | 価格: $' || nft_record.price || ' | 特別: ' || nft_record.is_special || ' | 新しい上限: ' || (nft_record.daily_rate_limit * 100) || '%';
        RAISE NOTICE '%', debug_msg;
    END LOOP;
    
    debug_msg := '🎯 SHOGUN NFT 1000 (Special) 修正完了';
    RAISE NOTICE '%', debug_msg;
END $$;

-- 最終確認クエリ
SELECT 
    '🎯 SHOGUN NFT 1000修正結果' as section,
    name,
    price,
    is_special,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    CASE 
        WHEN name = 'SHOGUN NFT 1000 (Special)' AND daily_rate_limit = 0.0125 THEN '✅ 修正成功！'
        WHEN name = 'SHOGUN NFT 1000' AND daily_rate_limit = 0.010 THEN '✅ 正しい'
        ELSE '❌ まだ問題あり'
    END as status
FROM nfts
WHERE name LIKE '%1000%' AND is_active = true
ORDER BY is_special DESC;
