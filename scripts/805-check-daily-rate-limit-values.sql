-- SHOGUN NFT 1000 (Special)の日利上限値確認

SELECT '=== CHECKING DAILY RATE LIMIT VALUES ===' as section;

-- 1. SHOGUN NFT 1000 (Special)の基本情報確認
SELECT 'SHOGUN NFT 1000 (Special) basic info:' as info;
SELECT 
    id,
    name,
    price,
    daily_rate_limit,
    daily_rate_limit * 100 as display_value_if_multiplied,
    is_special
FROM nfts 
WHERE name LIKE '%SHOGUN NFT 1000%' OR price = 1000;

-- 2. 全NFTの日利上限値確認
SELECT 'All NFTs daily rate limits:' as info;
SELECT 
    id,
    name,
    price,
    daily_rate_limit,
    CASE 
        WHEN daily_rate_limit > 10 THEN 'LOOKS LIKE PERCENTAGE (needs /100)'
        WHEN daily_rate_limit < 0.1 THEN 'LOOKS LIKE DECIMAL (needs *100 for display)'
        ELSE 'NORMAL RANGE'
    END as analysis
FROM nfts 
ORDER BY daily_rate_limit DESC;

SELECT 'Analysis complete - Check if daily_rate_limit values need adjustment' as conclusion;