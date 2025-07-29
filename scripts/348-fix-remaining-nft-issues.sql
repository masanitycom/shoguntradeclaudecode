-- 残りの問題のあるNFTを修正

DO $$
DECLARE
    update_count INTEGER := 0;
BEGIN
    RAISE NOTICE '🔧 残りの問題NFTを修正中...';
    
    -- 特別NFT $1100 → 1.00%
    UPDATE nfts 
    SET daily_rate_limit = 1.00, updated_at = NOW()
    WHERE id = '1687aae0-3871-44db-a3e1-a0ac41bc533e';
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE '✅ SHOGUN NFT 1100 (特別): % 件更新', update_count;
    
    -- 特別NFT $2100 → 1.00%
    UPDATE nfts 
    SET daily_rate_limit = 1.00, updated_at = NOW()
    WHERE id = '12c881e6-b771-4585-a61a-6ccee4bc6ddc';
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE '✅ SHOGUN NFT 2100 (特別): % 件更新', update_count;
    
    -- 全ての特別NFTで0.01%のものを一括修正
    UPDATE nfts 
    SET daily_rate_limit = CASE 
        WHEN price IN (100, 200, 300, 500, 600) THEN 0.50
        WHEN price = 1000 THEN 1.25
        WHEN price BETWEEN 1100 AND 8000 THEN 1.00
        WHEN price = 50000 THEN 1.75
        ELSE daily_rate_limit
    END,
    updated_at = NOW()
    WHERE is_special = true AND daily_rate_limit = 0.01;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE '✅ 特別NFT一括修正: % 件更新', update_count;
    
    RAISE NOTICE '🎯 問題NFTの修正が完了しました';
END $$;

-- 修正結果の確認
SELECT 
    '📊 修正後のNFT確認' as status,
    id,
    name,
    price,
    daily_rate_limit,
    is_special,
    CASE 
        WHEN daily_rate_limit = 0.01 AND is_special = true THEN '❌ まだ問題あり'
        ELSE '✅ 正常'
    END as fix_status
FROM nfts
WHERE id IN ('1687aae0-3871-44db-a3e1-a0ac41bc533e', '12c881e6-b771-4585-a61a-6ccee4bc6ddc')
OR (is_special = true AND daily_rate_limit = 0.01);

-- 全NFTの最終確認
SELECT 
    '📋 全NFT最終確認' as status,
    price,
    daily_rate_limit,
    is_special,
    COUNT(*) as nft_count,
    string_agg(name, ', ') as nft_names
FROM nfts 
GROUP BY price, daily_rate_limit, is_special
ORDER BY price, is_special;
