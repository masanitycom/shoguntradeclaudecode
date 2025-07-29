-- 緊急NFT分類修正 - 一つずつ確実に実行

-- 1. 現在の状況を再確認
SELECT 'Current Status Check' as status;
SELECT id, name, price, daily_rate_limit, 
       (daily_rate_limit * 100)::text || '%' as current_percentage
FROM nfts 
WHERE name IN (
    'SHOGUN NFT 100', 'SHOGUN NFT 200', 'SHOGUN NFT 3000', 'SHOGUN NFT 3175',
    'SHOGUN NFT 4000', 'SHOGUN NFT 5000', 'SHOGUN NFT 6600', 'SHOGUN NFT 8000',
    'SHOGUN NFT 10000', 'SHOGUN NFT 30000'
)
ORDER BY price::numeric;

-- 2. 一つずつ確実に更新
-- SHOGUN NFT 100 → 0.5%
UPDATE nfts 
SET daily_rate_limit = 0.005 
WHERE name = 'SHOGUN NFT 100';

SELECT 'Updated SHOGUN NFT 100' as status, 
       name, (daily_rate_limit * 100)::text || '%' as new_rate
FROM nfts WHERE name = 'SHOGUN NFT 100';

-- SHOGUN NFT 200 → 0.5%
UPDATE nfts 
SET daily_rate_limit = 0.005 
WHERE name = 'SHOGUN NFT 200';

SELECT 'Updated SHOGUN NFT 200' as status, 
       name, (daily_rate_limit * 100)::text || '%' as new_rate
FROM nfts WHERE name = 'SHOGUN NFT 200';

-- SHOGUN NFT 3000 → 1.25%
UPDATE nfts 
SET daily_rate_limit = 0.0125 
WHERE name = 'SHOGUN NFT 3000';

SELECT 'Updated SHOGUN NFT 3000' as status, 
       name, (daily_rate_limit * 100)::text || '%' as new_rate
FROM nfts WHERE name = 'SHOGUN NFT 3000';

-- SHOGUN NFT 3175 → 1.25%
UPDATE nfts 
SET daily_rate_limit = 0.0125 
WHERE name = 'SHOGUN NFT 3175';

SELECT 'Updated SHOGUN NFT 3175' as status, 
       name, (daily_rate_limit * 100)::text || '%' as new_rate
FROM nfts WHERE name = 'SHOGUN NFT 3175';

-- SHOGUN NFT 4000 → 1.25%
UPDATE nfts 
SET daily_rate_limit = 0.0125 
WHERE name = 'SHOGUN NFT 4000';

SELECT 'Updated SHOGUN NFT 4000' as status, 
       name, (daily_rate_limit * 100)::text || '%' as new_rate
FROM nfts WHERE name = 'SHOGUN NFT 4000';

-- SHOGUN NFT 5000 → 1.25%
UPDATE nfts 
SET daily_rate_limit = 0.0125 
WHERE name = 'SHOGUN NFT 5000';

SELECT 'Updated SHOGUN NFT 5000' as status, 
       name, (daily_rate_limit * 100)::text || '%' as new_rate
FROM nfts WHERE name = 'SHOGUN NFT 5000';

-- SHOGUN NFT 6600 → 1.25%
UPDATE nfts 
SET daily_rate_limit = 0.0125 
WHERE name = 'SHOGUN NFT 6600';

SELECT 'Updated SHOGUN NFT 6600' as status, 
       name, (daily_rate_limit * 100)::text || '%' as new_rate
FROM nfts WHERE name = 'SHOGUN NFT 6600';

-- SHOGUN NFT 8000 → 1.25%
UPDATE nfts 
SET daily_rate_limit = 0.0125 
WHERE name = 'SHOGUN NFT 8000';

SELECT 'Updated SHOGUN NFT 8000' as status, 
       name, (daily_rate_limit * 100)::text || '%' as new_rate
FROM nfts WHERE name = 'SHOGUN NFT 8000';

-- SHOGUN NFT 10000 → 1.25%
UPDATE nfts 
SET daily_rate_limit = 0.0125 
WHERE name = 'SHOGUN NFT 10000';

SELECT 'Updated SHOGUN NFT 10000' as status, 
       name, (daily_rate_limit * 100)::text || '%' as new_rate
FROM nfts WHERE name = 'SHOGUN NFT 10000';

-- SHOGUN NFT 30000 → 1.5%
UPDATE nfts 
SET daily_rate_limit = 0.015 
WHERE name = 'SHOGUN NFT 30000';

SELECT 'Updated SHOGUN NFT 30000' as status, 
       name, (daily_rate_limit * 100)::text || '%' as new_rate
FROM nfts WHERE name = 'SHOGUN NFT 30000';

-- 3. 最終確認
SELECT 'Final Verification' as status;
SELECT name, price, 
       (daily_rate_limit * 100)::text || '%' as actual_rate,
       CASE 
           WHEN price <= 200 THEN '0.5%'
           WHEN price <= 2999 THEN '1.0%'
           WHEN price <= 29999 THEN '1.25%'
           WHEN price <= 99999 THEN '1.5%'
           ELSE '2.0%'
       END as expected_rate,
       CASE 
           WHEN price <= 200 AND daily_rate_limit = 0.005 THEN '✅ CORRECT'
           WHEN price BETWEEN 201 AND 2999 AND daily_rate_limit = 0.01 THEN '✅ CORRECT'
           WHEN price BETWEEN 3000 AND 29999 AND daily_rate_limit = 0.0125 THEN '✅ CORRECT'
           WHEN price BETWEEN 30000 AND 99999 AND daily_rate_limit = 0.015 THEN '✅ CORRECT'
           WHEN price >= 100000 AND daily_rate_limit = 0.02 THEN '✅ CORRECT'
           ELSE '❌ STILL WRONG'
       END as verification_status
FROM nfts 
WHERE name IN (
    'SHOGUN NFT 100', 'SHOGUN NFT 200', 'SHOGUN NFT 3000', 'SHOGUN NFT 3175',
    'SHOGUN NFT 4000', 'SHOGUN NFT 5000', 'SHOGUN NFT 6600', 'SHOGUN NFT 8000',
    'SHOGUN NFT 10000', 'SHOGUN NFT 30000'
)
ORDER BY price::numeric;

-- 4. 全体の成功率確認
SELECT 'Overall Success Rate' as check_type,
       COUNT(*) as total_nfts,
       COUNT(CASE 
           WHEN (price <= 200 AND daily_rate_limit = 0.005) OR
                (price BETWEEN 201 AND 2999 AND daily_rate_limit = 0.01) OR
                (price BETWEEN 3000 AND 29999 AND daily_rate_limit = 0.0125) OR
                (price BETWEEN 30000 AND 99999 AND daily_rate_limit = 0.015) OR
                (price >= 100000 AND daily_rate_limit = 0.02)
           THEN 1 
       END) as perfect_matches,
       ROUND(
           COUNT(CASE 
               WHEN (price <= 200 AND daily_rate_limit = 0.005) OR
                    (price BETWEEN 201 AND 2999 AND daily_rate_limit = 0.01) OR
                    (price BETWEEN 3000 AND 29999 AND daily_rate_limit = 0.0125) OR
                    (price BETWEEN 30000 AND 99999 AND daily_rate_limit = 0.015) OR
                    (price >= 100000 AND daily_rate_limit = 0.02)
               THEN 1 
           END)::NUMERIC / COUNT(*) * 100, 2
       ) as success_percentage
FROM nfts;

-- 5. 問題があるNFTの詳細確認
SELECT 'Remaining Issues' as status;
SELECT name, price, daily_rate_limit, 
       (daily_rate_limit * 100)::text || '%' as current_rate,
       CASE 
           WHEN price <= 200 THEN '0.5%'
           WHEN price <= 2999 THEN '1.0%'
           WHEN price <= 29999 THEN '1.25%'
           WHEN price <= 99999 THEN '1.5%'
           ELSE '2.0%'
       END as should_be
FROM nfts 
WHERE NOT (
    (price <= 200 AND daily_rate_limit = 0.005) OR
    (price BETWEEN 201 AND 2999 AND daily_rate_limit = 0.01) OR
    (price BETWEEN 3000 AND 29999 AND daily_rate_limit = 0.0125) OR
    (price BETWEEN 30000 AND 99999 AND daily_rate_limit = 0.015) OR
    (price >= 100000 AND daily_rate_limit = 0.02)
)
ORDER BY price::numeric;

SELECT 'Emergency fix completed!' as final_status;
