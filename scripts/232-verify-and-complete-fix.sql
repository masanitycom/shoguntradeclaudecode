-- 修正の検証と完了確認

-- 1. 全NFTの現在の状況
SELECT 'All NFTs Current Status' as status;
SELECT name, price, daily_rate_limit,
       (daily_rate_limit * 100)::text || '%' as current_percentage,
       CASE 
           WHEN price <= 200 THEN '0.5%グループ'
           WHEN price <= 2999 THEN '1.0%グループ'
           WHEN price <= 29999 THEN '1.25%グループ'
           WHEN price <= 99999 THEN '1.5%グループ'
           ELSE '2.0%グループ'
       END as expected_group,
       CASE 
           WHEN price <= 200 AND daily_rate_limit = 0.005 THEN '✅ PERFECT'
           WHEN price BETWEEN 201 AND 2999 AND daily_rate_limit = 0.01 THEN '✅ PERFECT'
           WHEN price BETWEEN 3000 AND 29999 AND daily_rate_limit = 0.0125 THEN '✅ PERFECT'
           WHEN price BETWEEN 30000 AND 99999 AND daily_rate_limit = 0.015 THEN '✅ PERFECT'
           WHEN price >= 100000 AND daily_rate_limit = 0.02 THEN '✅ PERFECT'
           ELSE '❌ NEEDS FIX'
       END as status
FROM nfts 
ORDER BY price::numeric;

-- 2. グループ別統計（修正版）
SELECT 'Group Statistics' as status;
WITH price_groups AS (
    SELECT 
        name,
        price,
        daily_rate_limit,
        CASE 
            WHEN price <= 200 THEN '0.5%グループ'
            WHEN price <= 2999 THEN '1.0%グループ'
            WHEN price <= 29999 THEN '1.25%グループ'
            WHEN price <= 99999 THEN '1.5%グループ'
            ELSE '2.0%グループ'
        END as price_group,
        CASE 
            WHEN (price <= 200 AND daily_rate_limit = 0.005) OR
                 (price BETWEEN 201 AND 2999 AND daily_rate_limit = 0.01) OR
                 (price BETWEEN 3000 AND 29999 AND daily_rate_limit = 0.0125) OR
                 (price BETWEEN 30000 AND 99999 AND daily_rate_limit = 0.015) OR
                 (price >= 100000 AND daily_rate_limit = 0.02)
            THEN 1 
            ELSE 0
        END as is_correct
    FROM nfts
)
SELECT 
    price_group,
    COUNT(*) as total_nfts,
    SUM(is_correct) as correctly_classified,
    ROUND(
        (SUM(is_correct)::NUMERIC / COUNT(*)) * 100, 1
    ) as success_rate_percent
FROM price_groups
GROUP BY price_group
ORDER BY 
    CASE price_group
        WHEN '0.5%グループ' THEN 1
        WHEN '1.0%グループ' THEN 2
        WHEN '1.25%グループ' THEN 3
        WHEN '1.5%グループ' THEN 4
        ELSE 5
    END;

-- 3. 最終成功率
SELECT 'Final Success Rate' as status,
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

-- 4. 残っている問題があれば表示
SELECT 'Remaining Issues (if any)' as status;
SELECT name, price, daily_rate_limit,
       (daily_rate_limit * 100)::text || '%' as current_rate,
       CASE 
           WHEN price <= 200 THEN '0.5%'
           WHEN price <= 2999 THEN '1.0%'
           WHEN price <= 29999 THEN '1.25%'
           WHEN price <= 99999 THEN '1.5%'
           ELSE '2.0%'
       END as should_be_rate
FROM nfts 
WHERE NOT (
    (price <= 200 AND daily_rate_limit = 0.005) OR
    (price BETWEEN 201 AND 2999 AND daily_rate_limit = 0.01) OR
    (price BETWEEN 3000 AND 29999 AND daily_rate_limit = 0.0125) OR
    (price BETWEEN 30000 AND 99999 AND daily_rate_limit = 0.015) OR
    (price >= 100000 AND daily_rate_limit = 0.02)
)
ORDER BY price::numeric;

-- 5. 完了メッセージ
SELECT CASE 
    WHEN (SELECT COUNT(*) FROM nfts WHERE NOT (
        (price <= 200 AND daily_rate_limit = 0.005) OR
        (price BETWEEN 201 AND 2999 AND daily_rate_limit = 0.01) OR
        (price BETWEEN 3000 AND 29999 AND daily_rate_limit = 0.0125) OR
        (price BETWEEN 30000 AND 99999 AND daily_rate_limit = 0.015) OR
        (price >= 100000 AND daily_rate_limit = 0.02)
    )) = 0 
    THEN '🎉 ALL NFTs PERFECTLY CLASSIFIED! 100% SUCCESS!'
    ELSE '⚠️ Some issues remain. Check the results above.'
END as final_result;
