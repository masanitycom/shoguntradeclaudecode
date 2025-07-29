-- 全NFTの日利上限を仕様書とCSVデータに基づいて完全修正

DO $$
DECLARE
    update_count INTEGER := 0;
BEGIN
    RAISE NOTICE '🚀 NFT日利上限の包括的修正を開始します';
    
    -- 価格帯別の日利上限修正（通常NFT）
    
    -- $100, $200 → 0.01% (現在の設定を維持)
    UPDATE nfts 
    SET daily_rate_limit = 0.01, updated_at = NOW()
    WHERE price IN (100, 200) AND is_special = false;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE '✅ $100-200 NFT: % 件更新', update_count;
    
    -- $300, $500 → 0.50%
    UPDATE nfts 
    SET daily_rate_limit = 0.50, updated_at = NOW()
    WHERE price IN (300, 500) AND is_special = false;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE '✅ $300-500 NFT: % 件更新', update_count;
    
    -- $600 → 0.01% (現在の設定を維持)
    UPDATE nfts 
    SET daily_rate_limit = 0.01, updated_at = NOW()
    WHERE price = 600 AND is_special = false;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE '✅ $600 NFT: % 件更新', update_count;
    
    -- $1000, $1200, $3000, $5000 → 1.00%
    UPDATE nfts 
    SET daily_rate_limit = 1.00, updated_at = NOW()
    WHERE price IN (1000, 1200, 3000, 5000) AND is_special = false;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE '✅ $1000-5000 NFT: % 件更新', update_count;
    
    -- $1100, $1177, $1217, $1227, $1300, $1350, $1500, $1600, $1836, $2000, $2100 → 0.01%
    UPDATE nfts 
    SET daily_rate_limit = 0.01, updated_at = NOW()
    WHERE price IN (1100, 1177, 1217, 1227, 1300, 1350, 1500, 1600, 1836, 2000, 2100) AND is_special = false;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE '✅ その他中価格帯NFT: % 件更新', update_count;
    
    -- $3175, $4000, $6600, $8000 → 0.01%
    UPDATE nfts 
    SET daily_rate_limit = 0.01, updated_at = NOW()
    WHERE price IN (3175, 4000, 6600, 8000) AND is_special = false;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE '✅ 高価格帯NFT: % 件更新', update_count;
    
    -- $10000 → 1.25%
    UPDATE nfts 
    SET daily_rate_limit = 1.25, updated_at = NOW()
    WHERE price = 10000 AND is_special = false;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE '✅ $10000 NFT: % 件更新', update_count;
    
    -- $30000 → 1.50%
    UPDATE nfts 
    SET daily_rate_limit = 1.50, updated_at = NOW()
    WHERE price = 30000 AND is_special = false;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE '✅ $30000 NFT: % 件更新', update_count;
    
    -- $100000 → 2.00%
    UPDATE nfts 
    SET daily_rate_limit = 2.00, updated_at = NOW()
    WHERE price = 100000 AND is_special = false;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE '✅ $100000 NFT: % 件更新', update_count;
    
    -- 特別NFTの修正（CSVデータに基づく）
    
    -- 特別NFT $100-600 → 0.50%
    UPDATE nfts 
    SET daily_rate_limit = 0.50, updated_at = NOW()
    WHERE price IN (100, 200, 300, 500, 600) AND is_special = true;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE '✅ 特別NFT $100-600: % 件更新', update_count;
    
    -- 特別NFT $1000 → 1.25%
    UPDATE nfts 
    SET daily_rate_limit = 1.25, updated_at = NOW()
    WHERE price = 1000 AND is_special = true;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE '✅ 特別NFT $1000: % 件更新', update_count;
    
    -- 特別NFT $1177-8000 → 1.00%
    UPDATE nfts 
    SET daily_rate_limit = 1.00, updated_at = NOW()
    WHERE price IN (1177, 1200, 1217, 1227, 1300, 1350, 1500, 1600, 1836, 2000, 3175, 4000, 6600, 8000) 
    AND is_special = true;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE '✅ 特別NFT $1177-8000: % 件更新', update_count;
    
    -- 特別NFT $50000 → 1.75%
    UPDATE nfts 
    SET daily_rate_limit = 1.75, updated_at = NOW()
    WHERE price = 50000 AND is_special = true;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE '✅ 特別NFT $50000: % 件更新', update_count;
    
    RAISE NOTICE '🎯 NFT日利上限の修正が完了しました';
END $$;
