-- 現在のNFT日利上限を確認
SELECT id, name, price, daily_rate_limit, is_special, is_active
FROM nfts 
WHERE name LIKE '%SHOGUN%'
ORDER BY price;

-- 特に確認したいNFT
SELECT id, name, price, daily_rate_limit, is_special, is_active
FROM nfts 
WHERE name IN ('SHOGUN NFT 1000 (Special)', 'SHOGUN NFT 10000');
