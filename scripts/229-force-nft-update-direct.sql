-- NFTの日利上限を強制的に更新（直接UPDATE）

-- 1. 現在の問題を確認
SELECT 'Before Force Update' as status, id, name, 
       (daily_rate_limit * 100)::text || '%' as current_rate,
       price::text as price
FROM nfts 
WHERE id IN (
    'e36d5c5c-8d06-4d80-a2e2-64fe84a1317e', -- SHOGUN NFT 100
    '2c25b2c3-599c-478c-b857-eed69a216f6b', -- SHOGUN NFT 200
    '12289431-9adf-40c2-b17b-97f7ff72e727', -- SHOGUN NFT 3000
    '940c0f3a-dc63-4fcd-85b8-9c18d3c32538', -- SHOGUN NFT 3175
    '2a47896d-8927-4d26-9c92-4274fa68b25c', -- SHOGUN NFT 4000
    '36ccf718-07d2-4d1a-a874-c5e4be89fdf2', -- SHOGUN NFT 5000
    'f9ddbf4d-44d8-405d-9358-686a4c313947', -- SHOGUN NFT 6600
    'ccdf5142-4fcf-40f9-82da-6c433d494569', -- SHOGUN NFT 8000
    'ea1973a2-dece-4e69-b12e-62e419914e4d', -- SHOGUN NFT 10000
    '240f2ce8-9f58-4c8b-888a-c32c2953df4e'  -- SHOGUN NFT 30000
)
ORDER BY price::numeric;

-- 2. 強制的に個別更新（トランザクション内で実行）
BEGIN;

-- SHOGUN NFT 100, 200 → 0.5%グループ (0.005)
UPDATE nfts SET daily_rate_limit = 0.005 WHERE id = 'e36d5c5c-8d06-4d80-a2e2-64fe84a1317e';
UPDATE nfts SET daily_rate_limit = 0.005 WHERE id = '2c25b2c3-599c-478c-b857-eed69a216f6b';

-- SHOGUN NFT 3000, 3175, 4000, 5000, 6600, 8000, 10000 → 1.25%グループ (0.0125)
UPDATE nfts SET daily_rate_limit = 0.0125 WHERE id = '12289431-9adf-40c2-b17b-97f7ff72e727';
UPDATE nfts SET daily_rate_limit = 0.0125 WHERE id = '940c0f3a-dc63-4fcd-85b8-9c18d3c32538';
UPDATE nfts SET daily_rate_limit = 0.0125 WHERE id = '2a47896d-8927-4d26-9c92-4274fa68b25c';
UPDATE nfts SET daily_rate_limit = 0.0125 WHERE id = '36ccf718-07d2-4d1a-a874-c5e4be89fdf2';
UPDATE nfts SET daily_rate_limit = 0.0125 WHERE id = 'f9ddbf4d-44d8-405d-9358-686a4c313947';
UPDATE nfts SET daily_rate_limit = 0.0125 WHERE id = 'ccdf5142-4fcf-40f9-82da-6c433d494569';
UPDATE nfts SET daily_rate_limit = 0.0125 WHERE id = 'ea1973a2-dece-4e69-b12e-62e419914e4d';

-- SHOGUN NFT 30000 → 1.5%グループ (0.015)
UPDATE nfts SET daily_rate_limit = 0.015 WHERE id = '240f2ce8-9f58-4c8b-888a-c32c2953df4e';

COMMIT;

-- 3. 更新後の確認
SELECT 'After Force Update' as status, id, name, 
       (daily_rate_limit * 100)::text || '%' as updated_rate,
       price::text as price,
       CASE 
           WHEN price <= 200 AND daily_rate_limit = 0.005 THEN '✅ CORRECT'
           WHEN price BETWEEN 201 AND 2999 AND daily_rate_limit = 0.01 THEN '✅ CORRECT'
           WHEN price BETWEEN 3000 AND 29999 AND daily_rate_limit = 0.0125 THEN '✅ CORRECT'
           WHEN price BETWEEN 30000 AND 99999 AND daily_rate_limit = 0.015 THEN '✅ CORRECT'
           WHEN price >= 100000 AND daily_rate_limit = 0.02 THEN '✅ CORRECT'
           ELSE '❌ STILL WRONG'
       END as status
FROM nfts 
WHERE id IN (
    'e36d5c5c-8d06-4d80-a2e2-64fe84a1317e', -- SHOGUN NFT 100
    '2c25b2c3-599c-478c-b857-eed69a216f6b', -- SHOGUN NFT 200
    '12289431-9adf-40c2-b17b-97f7ff72e727', -- SHOGUN NFT 3000
    '940c0f3a-dc63-4fcd-85b8-9c18d3c32538', -- SHOGUN NFT 3175
    '2a47896d-8927-4d26-9c92-4274fa68b25c', -- SHOGUN NFT 4000
    '36ccf718-07d2-4d1a-a874-c5e4be89fdf2', -- SHOGUN NFT 5000
    'f9ddbf4d-44d8-405d-9358-686a4c313947', -- SHOGUN NFT 6600
    'ccdf5142-4fcf-40f9-82da-6c433d494569', -- SHOGUN NFT 8000
    'ea1973a2-dece-4e69-b12e-62e419914e4d', -- SHOGUN NFT 10000
    '240f2ce8-9f58-4c8b-888a-c32c2953df4e'  -- SHOGUN NFT 30000
)
ORDER BY price::numeric;

-- 4. 全体の最終確認
SELECT 'Final Check All NFTs' as status, name, 
       price::text as price,
       (daily_rate_limit * 100)::text || '%' as nft_rate,
       CASE 
           WHEN price <= 200 THEN '0.5%'
           WHEN price <= 2999 THEN '1.0%'
           WHEN price <= 29999 THEN '1.25%'
           WHEN price <= 99999 THEN '1.5%'
           ELSE '2.0%'
       END as expected_rate,
       CASE 
           WHEN price <= 200 AND daily_rate_limit = 0.005 THEN '✅ PERFECT'
           WHEN price BETWEEN 201 AND 2999 AND daily_rate_limit = 0.01 THEN '✅ PERFECT'
           WHEN price BETWEEN 3000 AND 29999 AND daily_rate_limit = 0.0125 THEN '✅ PERFECT'
           WHEN price BETWEEN 30000 AND 99999 AND daily_rate_limit = 0.015 THEN '✅ PERFECT'
           WHEN price >= 100000 AND daily_rate_limit = 0.02 THEN '✅ PERFECT'
           ELSE '❌ MISMATCH'
       END as status
FROM nfts 
ORDER BY price::numeric;

-- 5. 成功率の計算
SELECT 'Success Rate' as check_type,
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
