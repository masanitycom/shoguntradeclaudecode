-- NFTの日利上限は既に正しく設定されています
-- SHOGUN NFT 1000 (Special): 1.25%
-- SHOGUN NFT 10000: 1.25%

-- 確認のため現在の値を表示
SELECT 
    name,
    price,
    daily_rate_limit,
    is_special,
    CASE 
        WHEN name = 'SHOGUN NFT 1000 (Special)' AND daily_rate_limit = 1.25 THEN '✓ 正しい'
        WHEN name = 'SHOGUN NFT 10000' AND daily_rate_limit = 1.25 THEN '✓ 正しい'
        ELSE '要修正'
    END as status
FROM nfts 
WHERE name IN ('SHOGUN NFT 1000 (Special)', 'SHOGUN NFT 10000')
ORDER BY price;

-- もし修正が必要な場合のみ実行（現在は不要）
-- UPDATE nfts SET daily_rate_limit = 1.25 WHERE name = 'SHOGUN NFT 1000 (Special)';
-- UPDATE nfts SET daily_rate_limit = 1.25 WHERE name = 'SHOGUN NFT 10000';
