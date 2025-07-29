-- 最終修正：NFTの日利上限値をグループに合わせて正確に設定

-- 0.5%グループのNFTを0.005に設定
UPDATE nfts 
SET daily_rate_limit = 0.005
WHERE group_id = (SELECT id FROM daily_rate_groups WHERE group_name = '0.5%グループ');

-- 1.0%グループのNFTを0.010に設定
UPDATE nfts 
SET daily_rate_limit = 0.010
WHERE group_id = (SELECT id FROM daily_rate_groups WHERE group_name = '1.0%グループ');

-- 1.25%グループのNFTを0.0125に設定
UPDATE nfts 
SET daily_rate_limit = 0.0125
WHERE group_id = (SELECT id FROM daily_rate_groups WHERE group_name = '1.25%グループ');

-- 1.5%グループのNFTを0.015に設定
UPDATE nfts 
SET daily_rate_limit = 0.015
WHERE group_id = (SELECT id FROM daily_rate_groups WHERE group_name = '1.5%グループ');

-- 2.0%グループのNFTを0.020に設定
UPDATE nfts 
SET daily_rate_limit = 0.020
WHERE group_id = (SELECT id FROM daily_rate_groups WHERE group_name = '2.0%グループ');

-- 修正結果を確認
SELECT 
    'Final Perfect Classification' as check_type,
    n.name,
    n.price,
    (n.daily_rate_limit * 100) as nft_percentage,
    n.is_special,
    drg.group_name,
    (drg.daily_rate_limit * 100) as group_percentage,
    CASE 
        WHEN n.daily_rate_limit = drg.daily_rate_limit THEN '✅ PERFECT MATCH'
        ELSE '❌ MISMATCH'
    END as status
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.group_id = drg.id
ORDER BY n.price;

-- 最終グループサマリー
SELECT 
    'Perfect Group Summary' as check_type,
    drg.group_name,
    (drg.daily_rate_limit * 100) as percentage,
    COUNT(n.id) as nft_count,
    ROUND(AVG(n.price::numeric), 0) as avg_price,
    STRING_AGG(n.name, ', ' ORDER BY n.price) as nft_list
FROM daily_rate_groups drg
LEFT JOIN nfts n ON n.group_id = drg.id
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;

-- システム整合性チェック
SELECT 
    'System Integrity Check' as check_type,
    COUNT(*) as total_nfts,
    COUNT(CASE WHEN group_id IS NOT NULL THEN 1 END) as classified_nfts,
    COUNT(CASE WHEN group_id IS NULL THEN 1 END) as unclassified_nfts,
    COUNT(DISTINCT group_id) as groups_used
FROM nfts;

-- 週利システム準備完了チェック
SELECT 
    'Weekly Rate System Ready' as check_type,
    drg.group_name,
    (drg.daily_rate_limit * 100) as group_percentage,
    COUNT(n.id) as nft_count,
    CASE 
        WHEN COUNT(n.id) > 0 THEN '✅ READY FOR WEEKLY RATES'
        ELSE '⚠️ NO NFTS IN GROUP'
    END as weekly_rate_status
FROM daily_rate_groups drg
LEFT JOIN nfts n ON n.group_id = drg.id
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;
