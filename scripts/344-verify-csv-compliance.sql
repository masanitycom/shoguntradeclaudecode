-- CSVデータとの整合性確認

-- 現在のNFT設定とCSVデータの比較
SELECT 
    '📊 NFT日利上限設定確認' as status,
    price,
    daily_rate_limit,
    is_special,
    COUNT(*) as nft_count,
    string_agg(name, ', ') as nft_names
FROM nfts 
GROUP BY price, daily_rate_limit, is_special
ORDER BY price;

-- 仕様書との整合性チェック
WITH expected_rates AS (
    SELECT 100.00 as price, 0.01 as expected_rate, false as is_special
    UNION ALL SELECT 200.00, 0.01, false
    UNION ALL SELECT 300.00, 0.50, false
    UNION ALL SELECT 500.00, 0.50, false
    UNION ALL SELECT 600.00, 0.01, false
    UNION ALL SELECT 1000.00, 1.00, false
    UNION ALL SELECT 1200.00, 1.00, false
    UNION ALL SELECT 3000.00, 1.00, false
    UNION ALL SELECT 5000.00, 1.00, false
    UNION ALL SELECT 10000.00, 1.25, false
    UNION ALL SELECT 30000.00, 1.50, false
    UNION ALL SELECT 100000.00, 2.00, false
    -- 特別NFT
    UNION ALL SELECT 100.00, 0.50, true
    UNION ALL SELECT 200.00, 0.50, true
    UNION ALL SELECT 300.00, 0.50, true
    UNION ALL SELECT 500.00, 0.50, true
    UNION ALL SELECT 600.00, 0.50, true
    UNION ALL SELECT 1000.00, 1.25, true
    UNION ALL SELECT 50000.00, 1.75, true
)
SELECT 
    '🔍 仕様書との整合性チェック' as check_type,
    er.price,
    er.is_special,
    er.expected_rate,
    COALESCE(n.daily_rate_limit, 0) as current_rate,
    CASE 
        WHEN n.daily_rate_limit = er.expected_rate THEN '✅ 正常'
        WHEN n.daily_rate_limit IS NULL THEN '❌ NFT不存在'
        ELSE '⚠️ 不一致'
    END as status
FROM expected_rates er
LEFT JOIN nfts n ON n.price = er.price AND n.is_special = er.is_special
ORDER BY er.price, er.is_special;

-- 問題のあるNFTの特定
SELECT 
    '⚠️ 問題のあるNFT' as issue_type,
    id,
    name,
    price,
    daily_rate_limit,
    is_special,
    CASE 
        WHEN daily_rate_limit = 0.01 AND price IN (300, 500) AND is_special = false THEN '日利上限が低すぎる'
        WHEN daily_rate_limit = 0.01 AND price IN (1000, 1200, 3000, 5000) AND is_special = false THEN '日利上限が低すぎる'
        WHEN daily_rate_limit = 0.01 AND price = 10000 AND is_special = false THEN '日利上限が低すぎる'
        WHEN daily_rate_limit = 0.01 AND price = 30000 AND is_special = false THEN '日利上限が低すぎる'
        WHEN daily_rate_limit = 0.01 AND price = 100000 AND is_special = false THEN '日利上限が低すぎる'
        WHEN daily_rate_limit = 0.01 AND is_special = true THEN '特別NFTの日利上限が低すぎる'
        ELSE '不明な問題'
    END as issue_description
FROM nfts
WHERE 
    (daily_rate_limit = 0.01 AND price IN (300, 500) AND is_special = false) OR
    (daily_rate_limit = 0.01 AND price IN (1000, 1200, 3000, 5000) AND is_special = false) OR
    (daily_rate_limit = 0.01 AND price IN (10000, 30000, 100000) AND is_special = false) OR
    (daily_rate_limit = 0.01 AND is_special = true)
ORDER BY price;
