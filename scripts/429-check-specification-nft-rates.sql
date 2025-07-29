-- 仕様書に基づくNFT日利上限の確認

-- 現在のNFT設定と仕様書の比較
SELECT 
    '📋 現在のNFT設定' as section,
    name,
    price,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as current_rate,
    is_special,
    CASE 
        -- 通常NFT（is_special: false）
        WHEN is_special = false AND price = 300 THEN '0.5%'
        WHEN is_special = false AND price = 500 THEN '0.5%'
        WHEN is_special = false AND price = 1000 THEN '1.0%'
        WHEN is_special = false AND price = 3000 THEN '1.0%'
        WHEN is_special = false AND price = 5000 THEN '1.0%'
        WHEN is_special = false AND price = 10000 THEN '1.25%'
        WHEN is_special = false AND price = 30000 THEN '1.5%'
        WHEN is_special = false AND price = 50000 THEN '1.75%'
        WHEN is_special = false AND price = 100000 THEN '2.0%'
        
        -- 特別NFT（is_special: true）
        WHEN is_special = true AND price IN (100, 200, 600) THEN '0.5%'
        WHEN is_special = true AND price = 1000 THEN '1.25%'
        WHEN is_special = true AND price IN (1100, 1177, 1217, 1227, 1300, 1350, 1500, 1600, 1836, 2000, 2100, 3175, 4000, 6600, 8000) THEN '1.0%'
        
        ELSE '不明'
    END as should_be_rate,
    CASE 
        WHEN is_special = false AND price = 300 AND daily_rate_limit != 0.005 THEN '要修正'
        WHEN is_special = false AND price = 500 AND daily_rate_limit != 0.005 THEN '要修正'
        WHEN is_special = false AND price = 1000 AND daily_rate_limit != 0.010 THEN '要修正'
        WHEN is_special = false AND price = 3000 AND daily_rate_limit != 0.010 THEN '要修正'
        WHEN is_special = false AND price = 5000 AND daily_rate_limit != 0.010 THEN '要修正'
        WHEN is_special = false AND price = 10000 AND daily_rate_limit != 0.0125 THEN '要修正'
        WHEN is_special = false AND price = 30000 AND daily_rate_limit != 0.015 THEN '要修正'
        WHEN is_special = false AND price = 50000 AND daily_rate_limit != 0.0175 THEN '要修正'
        WHEN is_special = false AND price = 100000 AND daily_rate_limit != 0.020 THEN '要修正'
        
        WHEN is_special = true AND price IN (100, 200, 600) AND daily_rate_limit != 0.005 THEN '要修正'
        WHEN is_special = true AND price = 1000 AND daily_rate_limit != 0.0125 THEN '要修正'
        WHEN is_special = true AND price IN (1100, 1177, 1217, 1227, 1300, 1350, 1500, 1600, 1836, 2000, 2100, 3175, 4000, 6600, 8000) AND daily_rate_limit != 0.010 THEN '要修正'
        
        ELSE '正常'
    END as status
FROM nfts
WHERE is_active = true
ORDER BY is_special, price;

-- 仕様書の正しい設定一覧
SELECT 
    '📖 仕様書の正しい設定' as section,
    'SHOGUN NFT 300' as nft_name,
    '300.00' as price,
    'false' as is_special,
    '0.5%' as correct_rate
UNION ALL
SELECT '📖 仕様書の正しい設定', 'SHOGUN NFT 500', '500.00', 'false', '0.5%'
UNION ALL
SELECT '📖 仕様書の正しい設定', 'SHOGUN NFT 1,000 (通常)', '1000.00', 'false', '1.0%'
UNION ALL
SELECT '📖 仕様書の正しい設定', 'SHOGUN NFT 3,000', '3000.00', 'false', '1.0%'
UNION ALL
SELECT '📖 仕様書の正しい設定', 'SHOGUN NFT 5,000', '5000.00', 'false', '1.0%'
UNION ALL
SELECT '📖 仕様書の正しい設定', 'SHOGUN NFT 10,000', '10000.00', 'false', '1.25%'
UNION ALL
SELECT '📖 仕様書の正しい設定', 'SHOGUN NFT 30,000', '30000.00', 'false', '1.5%'
UNION ALL
SELECT '📖 仕様書の正しい設定', 'SHOGUN NFT 50,000', '50000.00', 'false', '1.75%'
UNION ALL
SELECT '📖 仕様書の正しい設定', 'SHOGUN NFT 100,000', '100000.00', 'false', '2.0%'
UNION ALL
SELECT '📖 仕様書の正しい設定', 'SHOGUN NFT 100 (特別)', '100.00', 'true', '0.5%'
UNION ALL
SELECT '📖 仕様書の正しい設定', 'SHOGUN NFT 200 (特別)', '200.00', 'true', '0.5%'
UNION ALL
SELECT '📖 仕様書の正しい設定', 'SHOGUN NFT 600 (特別)', '600.00', 'true', '0.5%'
UNION ALL
SELECT '📖 仕様書の正しい設定', 'SHOGUN NFT 1,000 (特別)', '1000.00', 'true', '1.25%'
UNION ALL
SELECT '📖 仕様書の正しい設定', 'その他特別NFT', '1100-8000', 'true', '1.0%';
