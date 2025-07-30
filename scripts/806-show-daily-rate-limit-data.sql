-- 日利上限値の詳細確認（結果を表示）

-- 1. SHOGUN NFT 1000 (Special)の詳細情報
SELECT 
    id,
    name,
    price,
    daily_rate_limit,
    daily_rate_limit * 100 as "if_multiplied_by_100",
    daily_rate_limit / 100 as "if_divided_by_100",
    is_special
FROM nfts 
WHERE name LIKE '%SHOGUN NFT 1000%' OR price = 1000;

-- 2. 全NFTの日利上限値詳細
SELECT 
    id,
    name,
    price,
    daily_rate_limit as "raw_value",
    CASE 
        WHEN daily_rate_limit >= 1 THEN 'STORED AS PERCENTAGE - needs /100'
        WHEN daily_rate_limit < 1 THEN 'STORED AS DECIMAL - display as is'
        ELSE 'UNKNOWN'
    END as "storage_format"
FROM nfts 
ORDER BY daily_rate_limit DESC;