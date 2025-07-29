-- 個別NFTのIDを使った確実な日利上限更新

-- 1. 更新前の問題確認
SELECT 'Current Problems' as status, id, name, 
       (daily_rate_limit * 100)::text || '%' as current_rate,
       CASE 
           WHEN price <= 200 THEN '0.0050'
           WHEN price <= 2999 THEN '0.0100'
           WHEN price <= 29999 THEN '0.0125'
           WHEN price <= 99999 THEN '0.0150'
           ELSE '0.0200'
       END as target_rate,
       CASE 
           WHEN price <= 200 THEN '0.5%グループ'
           WHEN price <= 2999 THEN '1.0%グループ'
           WHEN price <= 29999 THEN '1.25%グループ'
           WHEN price <= 99999 THEN '1.5%グループ'
           ELSE '2.0%グループ'
       END as group_name
FROM nfts 
WHERE (daily_rate_limit * 100)::text != CASE 
    WHEN price <= 200 THEN '0.50'
    WHEN price <= 2999 THEN '1.00'
    WHEN price <= 29999 THEN '1.25'
    WHEN price <= 99999 THEN '1.50'
    ELSE '2.00'
END
ORDER BY price;

-- 2. 個別ID指定での確実な更新
-- SHOGUN NFT 100, 200 → 0.5%グループ
UPDATE nfts SET daily_rate_limit = 0.0050 WHERE id = 'e36d5c5c-8d06-4d80-a2e2-64fe84a1317e';
UPDATE nfts SET daily_rate_limit = 0.0050 WHERE id = '2c25b2c3-599c-478c-b857-eed69a216f6b';

-- SHOGUN NFT 3000, 3175, 4000, 5000, 6600, 8000, 10000 → 1.25%グループ
UPDATE nfts SET daily_rate_limit = 0.0125 WHERE id = '12289431-9adf-40c2-b17b-97f7ff72e727';
UPDATE nfts SET daily_rate_limit = 0.0125 WHERE id = '940c0f3a-dc63-4fcd-85b8-9c18d3c32538';
UPDATE nfts SET daily_rate_limit = 0.0125 WHERE id = '2a47896d-8927-4d26-9c92-4274fa68b25c';
UPDATE nfts SET daily_rate_limit = 0.0125 WHERE id = '36ccf718-07d2-4d1a-a874-c5e4be89fdf2';
UPDATE nfts SET daily_rate_limit = 0.0125 WHERE id = 'f9ddbf4d-44d8-405d-9358-686a4c313947';
UPDATE nfts SET daily_rate_limit = 0.0125 WHERE id = 'ccdf5142-4fcf-40f9-82da-6c433d494569';
UPDATE nfts SET daily_rate_limit = 0.0125 WHERE id = 'ea1973a2-dece-4e69-b12e-62e419914e4d';

-- SHOGUN NFT 30000 → 1.5%グループ（仕様書通り）
UPDATE nfts SET daily_rate_limit = 0.0150 WHERE id = '240f2ce8-9f58-4c8b-888a-c32c2953df4e';

-- 3. 更新後の確認
SELECT 'After ID Update' as status, id, name, 
       (daily_rate_limit * 100)::text || '%' as updated_rate,
       CASE 
           WHEN price <= 200 THEN '0.0050'
           WHEN price <= 2999 THEN '0.0100'
           WHEN price <= 29999 THEN '0.0125'
           WHEN price <= 99999 THEN '0.0150'
           ELSE '0.0200'
       END as group_rate,
       CASE 
           WHEN price <= 200 THEN '0.5%グループ'
           WHEN price <= 2999 THEN '1.0%グループ'
           WHEN price <= 29999 THEN '1.25%グループ'
           WHEN price <= 99999 THEN '1.5%グループ'
           ELSE '2.0%グループ'
       END as group_name
FROM nfts 
ORDER BY price;

-- 4. 最終完璧チェック
SELECT 'Final Perfect Check' as check_type, name, 
       price::text as price,
       (daily_rate_limit * 100)::text as nft_percentage,
       is_special,
       CASE 
           WHEN price <= 200 THEN '0.5%グループ'
           WHEN price <= 2999 THEN '1.0%グループ'
           WHEN price <= 29999 THEN '1.25%グループ'
           WHEN price <= 99999 THEN '1.5%グループ'
           ELSE '2.0%グループ'
       END as group_name,
       CASE 
           WHEN price <= 200 THEN '0.5000'
           WHEN price <= 2999 THEN '1.0000'
           WHEN price <= 29999 THEN '1.2500'
           WHEN price <= 99999 THEN '1.5000'
           ELSE '2.0000'
       END as group_percentage,
       CASE 
           WHEN (daily_rate_limit * 100)::text = CASE 
               WHEN price <= 200 THEN '0.50'
               WHEN price <= 2999 THEN '1.00'
               WHEN price <= 29999 THEN '1.25'
               WHEN price <= 99999 THEN '1.50'
               ELSE '2.00'
           END THEN '✅ PERFECT MATCH'
           ELSE '❌ STILL MISMATCH'
       END as status
FROM nfts 
ORDER BY price;

-- 5. 残っている問題の確認
SELECT 'Remaining Issues' as check_type,
       COUNT(*) as remaining_mismatches
FROM nfts 
WHERE (daily_rate_limit * 100)::text != CASE 
    WHEN price <= 200 THEN '0.50'
    WHEN price <= 2999 THEN '1.00'
    WHEN price <= 29999 THEN '1.25'
    WHEN price <= 99999 THEN '1.50'
    ELSE '2.00'
END;

-- 6. 成功率の計算
SELECT 'Success Summary' as check_type,
       COUNT(*) as total_nfts,
       COUNT(CASE 
           WHEN (daily_rate_limit * 100)::text = CASE 
               WHEN price <= 200 THEN '0.50'
               WHEN price <= 2999 THEN '1.00'
               WHEN price <= 29999 THEN '1.25'
               WHEN price <= 99999 THEN '1.50'
               ELSE '2.00'
           END THEN 1 
       END) as perfect_matches,
       ROUND(
           COUNT(CASE 
               WHEN (daily_rate_limit * 100)::text = CASE 
                   WHEN price <= 200 THEN '0.50'
                   WHEN price <= 2999 THEN '1.00'
                   WHEN price <= 29999 THEN '1.25'
                   WHEN price <= 99999 THEN '1.50'
                   ELSE '2.00'
               END THEN 1 
           END)::NUMERIC / COUNT(*) * 100, 2
       )::text || '%' as success_percentage
FROM nfts;
