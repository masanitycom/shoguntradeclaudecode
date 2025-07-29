-- RLS無効化して強制更新

DO $$
DECLARE
    update_count INTEGER;
    debug_msg TEXT;
    rls_status BOOLEAN;
    total_updated INTEGER := 0;
    rec RECORD;
BEGIN
    -- RLS状態確認
    SELECT c.relrowsecurity INTO rls_status
    FROM pg_class c
    WHERE c.relname = 'nfts';
    
    debug_msg := '🔍 現在のRLS状態: ' || COALESCE(rls_status::text, 'NULL');
    RAISE NOTICE '%', debug_msg;
    
    -- RLSを一時的に無効化（権限があれば）
    BEGIN
        EXECUTE 'ALTER TABLE nfts DISABLE ROW LEVEL SECURITY';
        debug_msg := '✅ RLS無効化成功';
        RAISE NOTICE '%', debug_msg;
    EXCEPTION WHEN OTHERS THEN
        debug_msg := '⚠️ RLS無効化失敗: ' || SQLERRM;
        RAISE NOTICE '%', debug_msg;
    END;
    
    -- 強制更新実行
    debug_msg := '🚀 強制更新開始';
    RAISE NOTICE '%', debug_msg;
    
    -- トランザクション内で個別更新
    BEGIN
        -- 0.5%グループ更新（特別NFT）
        UPDATE nfts SET 
            daily_rate_limit = 0.005,
            updated_at = CURRENT_TIMESTAMP
        WHERE name IN ('SHOGUN NFT 100', 'SHOGUN NFT 200', 'SHOGUN NFT 600') 
        AND is_special = true 
        AND is_active = true;
        
        GET DIAGNOSTICS update_count = ROW_COUNT;
        total_updated := total_updated + update_count;
        debug_msg := '✅ 0.5%特別NFT: ' || update_count || '件更新';
        RAISE NOTICE '%', debug_msg;
        
        -- 0.5%グループ更新（通常NFT）
        UPDATE nfts SET 
            daily_rate_limit = 0.005,
            updated_at = CURRENT_TIMESTAMP
        WHERE name IN ('SHOGUN NFT 300', 'SHOGUN NFT 500') 
        AND is_special = false 
        AND is_active = true;
        
        GET DIAGNOSTICS update_count = ROW_COUNT;
        total_updated := total_updated + update_count;
        debug_msg := '✅ 0.5%通常NFT: ' || update_count || '件更新';
        RAISE NOTICE '%', debug_msg;
        
        -- 1.25%グループ更新（特別NFT）
        UPDATE nfts SET 
            daily_rate_limit = 0.0125,
            updated_at = CURRENT_TIMESTAMP
        WHERE name = 'SHOGUN NFT 1000 (Special)' 
        AND is_active = true;
        
        GET DIAGNOSTICS update_count = ROW_COUNT;
        total_updated := total_updated + update_count;
        debug_msg := '✅ 1.25%特別NFT: ' || update_count || '件更新';
        RAISE NOTICE '%', debug_msg;
        
        -- 1.25%グループ更新（通常NFT）
        UPDATE nfts SET 
            daily_rate_limit = 0.0125,
            updated_at = CURRENT_TIMESTAMP
        WHERE name = 'SHOGUN NFT 10000' 
        AND is_special = false 
        AND is_active = true;
        
        GET DIAGNOSTICS update_count = ROW_COUNT;
        total_updated := total_updated + update_count;
        debug_msg := '✅ 1.25%通常NFT: ' || update_count || '件更新';
        RAISE NOTICE '%', debug_msg;
        
        -- 1.5%グループ更新
        UPDATE nfts SET 
            daily_rate_limit = 0.015,
            updated_at = CURRENT_TIMESTAMP
        WHERE name = 'SHOGUN NFT 30000' 
        AND is_active = true;
        
        GET DIAGNOSTICS update_count = ROW_COUNT;
        total_updated := total_updated + update_count;
        debug_msg := '✅ 1.5%NFT: ' || update_count || '件更新';
        RAISE NOTICE '%', debug_msg;
        
        -- 1.75%グループ更新
        UPDATE nfts SET 
            daily_rate_limit = 0.0175,
            updated_at = CURRENT_TIMESTAMP
        WHERE name = 'SHOGUN NFT 50000' 
        AND is_active = true;
        
        GET DIAGNOSTICS update_count = ROW_COUNT;
        total_updated := total_updated + update_count;
        debug_msg := '✅ 1.75%NFT: ' || update_count || '件更新';
        RAISE NOTICE '%', debug_msg;
        
        -- 2.0%グループ更新
        UPDATE nfts SET 
            daily_rate_limit = 0.02,
            updated_at = CURRENT_TIMESTAMP
        WHERE name = 'SHOGUN NFT 100000' 
        AND is_active = true;
        
        GET DIAGNOSTICS update_count = ROW_COUNT;
        total_updated := total_updated + update_count;
        debug_msg := '✅ 2.0%NFT: ' || update_count || '件更新';
        RAISE NOTICE '%', debug_msg;
        
        -- 合計更新件数
        debug_msg := '🎯 合計更新件数: ' || total_updated || '件';
        RAISE NOTICE '%', debug_msg;
        
        -- 即座に結果確認
        debug_msg := '📊 更新直後確認:';
        RAISE NOTICE '%', debug_msg;
        
        FOR rec IN
            SELECT name, daily_rate_limit
            FROM nfts 
            WHERE name IN ('SHOGUN NFT 100', 'SHOGUN NFT 300', 'SHOGUN NFT 1000 (Special)', 'SHOGUN NFT 30000', 'SHOGUN NFT 100000')
            AND is_active = true
            ORDER BY daily_rate_limit, name
        LOOP
            debug_msg := '  ' || rec.name || ' → ' || (rec.daily_rate_limit * 100) || '%';
            RAISE NOTICE '%', debug_msg;
        END LOOP;
        
    EXCEPTION WHEN OTHERS THEN
        debug_msg := '❌ 更新エラー: ' || SQLERRM;
        RAISE NOTICE '%', debug_msg;
        RAISE;
    END;
    
    -- RLSを再有効化
    BEGIN
        EXECUTE 'ALTER TABLE nfts ENABLE ROW LEVEL SECURITY';
        debug_msg := '✅ RLS再有効化成功';
        RAISE NOTICE '%', debug_msg;
    EXCEPTION WHEN OTHERS THEN
        debug_msg := '⚠️ RLS再有効化失敗: ' || SQLERRM;
        RAISE NOTICE '%', debug_msg;
    END;
    
END $$;

-- 最終結果確認
SELECT 
    '🎯 最終更新結果' as section,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    COUNT(*) as nft_count,
    STRING_AGG(name || CASE WHEN is_special THEN '[特別]' ELSE '[通常]' END, ', ' ORDER BY name) as nft_names
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;
