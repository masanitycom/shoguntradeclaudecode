-- 全NFTの実際の日利上限を詳細調査

-- 1. 全NFTの現在の状況を詳細表示
SELECT 
    '🔍 全NFT詳細調査' as investigation,
    id,
    name,
    price,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as current_rate_display,
    is_special,
    is_active,
    created_at,
    updated_at
FROM nfts
ORDER BY price, name;

-- 2. 現在存在する日利上限の種類を確認
SELECT 
    '📊 現在の日利上限分布' as analysis,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    COUNT(*) as nft_count,
    ROUND(AVG(price), 2) as avg_price,
    MIN(price) as min_price,
    MAX(price) as max_price,
    STRING_AGG(name, ', ' ORDER BY price) as nft_names
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;

-- 3. 価格帯別の分析
SELECT 
    '💰 価格帯別分析' as price_analysis,
    CASE 
        WHEN price <= 600 THEN '$0-600'
        WHEN price <= 1000 THEN '$601-1000'
        WHEN price <= 5000 THEN '$1001-5000'
        WHEN price <= 10000 THEN '$5001-10000'
        WHEN price <= 30000 THEN '$10001-30000'
        WHEN price <= 50000 THEN '$30001-50000'
        ELSE '$50001+'
    END as price_range,
    COUNT(*) as nft_count,
    MIN(daily_rate_limit) as min_rate,
    MAX(daily_rate_limit) as max_rate,
    AVG(daily_rate_limit) as avg_rate,
    STRING_AGG(name || '($' || price || ',' || (daily_rate_limit*100) || '%)', ', ' ORDER BY price) as details
FROM nfts
WHERE is_active = true
GROUP BY 
    CASE 
        WHEN price <= 600 THEN '$0-600'
        WHEN price <= 1000 THEN '$601-1000'
        WHEN price <= 5000 THEN '$1001-5000'
        WHEN price <= 10000 THEN '$5001-10000'
        WHEN price <= 30000 THEN '$10001-30000'
        WHEN price <= 50000 THEN '$30001-50000'
        ELSE '$50001+'
    END
ORDER BY MIN(price);

-- 4. 問題のあるNFTを特定
SELECT 
    '❌ 問題のあるNFT特定' as problem_identification,
    name,
    price,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as current_rate,
    CASE 
        WHEN price <= 600 AND daily_rate_limit != 0.005 THEN '0.5%であるべき'
        WHEN price > 600 AND price <= 5000 AND daily_rate_limit != 0.010 THEN '1.0%であるべき'
        WHEN price > 5000 AND price <= 10000 AND daily_rate_limit != 0.0125 THEN '1.25%であるべき'
        WHEN price > 10000 AND price <= 30000 AND daily_rate_limit != 0.015 THEN '1.5%であるべき'
        WHEN price > 30000 AND price <= 50000 AND daily_rate_limit != 0.0175 THEN '1.75%であるべき'
        WHEN price > 50000 AND daily_rate_limit != 0.020 THEN '2.0%であるべき'
        ELSE '正常'
    END as should_be,
    CASE 
        WHEN price <= 600 THEN 0.005
        WHEN price <= 5000 THEN 0.010
        WHEN price <= 10000 THEN 0.0125
        WHEN price <= 30000 THEN 0.015
        WHEN price <= 50000 THEN 0.0175
        ELSE 0.020
    END as correct_rate
FROM nfts
WHERE is_active = true
ORDER BY price;

-- 5. daily_rate_groupsテーブルの現在の状況
SELECT 
    '🏷️ 現在のグループ定義' as group_definitions,
    id,
    group_name,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    description
FROM daily_rate_groups
ORDER BY daily_rate_limit;

-- 6. 実際のNFTとグループの対応関係
SELECT 
    '🔗 NFTとグループの対応関係' as mapping,
    drg.group_name,
    drg.daily_rate_limit as group_rate,
    COUNT(n.id) as actual_nft_count,
    STRING_AGG(n.name, ', ' ORDER BY n.price) as nft_list
FROM daily_rate_groups drg
LEFT JOIN nfts n ON ABS(n.daily_rate_limit - drg.daily_rate_limit) < 0.0001
    AND n.is_active = true
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;

-- 7. 最も重要：なぜ分類が失敗しているかの原因調査
SELECT 
    '🚨 分類失敗の原因調査' as root_cause,
    'NFTの実際の日利上限値' as check_type,
    daily_rate_limit,
    COUNT(*) as count,
    'これらのNFTが全て同じ値になっている' as issue
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
HAVING COUNT(*) > 10;
