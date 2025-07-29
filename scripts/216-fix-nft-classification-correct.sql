-- NFTの正しいグループ分類を修正
-- エラー修正: is_specialカラムを使用し、日利上限値も修正

-- 1. 現在の分類状況を確認
SELECT 
    'Current Classification' as check_type,
    n.name,
    n.price,
    n.daily_rate_limit,
    n.is_special,
    n.group_id,
    drg.group_name,
    drg.daily_rate_limit as group_limit
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.group_id = drg.id
ORDER BY n.price;

-- 2. 利用可能なグループを確認
SELECT 
    'Available Groups' as check_type,
    id,
    group_name,
    daily_rate_limit,
    description
FROM daily_rate_groups 
ORDER BY daily_rate_limit;

-- 3. まずNFTの日利上限値を正しい小数値に修正
-- 0.5% = 0.005
UPDATE nfts SET daily_rate_limit = 0.005 
WHERE name IN ('SHOGUN NFT 100', 'SHOGUN NFT 200');

-- 1.0% = 0.010
UPDATE nfts SET daily_rate_limit = 0.010 
WHERE name IN (
    'SHOGUN NFT 300', 'SHOGUN NFT 500', 'SHOGUN NFT 600',
    'SHOGUN NFT 1000', 'SHOGUN NFT 1100', 'SHOGUN NFT 1177',
    'SHOGUN NFT 1200', 'SHOGUN NFT 1217', 'SHOGUN NFT 1227',
    'SHOGUN NFT 1300', 'SHOGUN NFT 1350', 'SHOGUN NFT 1500',
    'SHOGUN NFT 1600', 'SHOGUN NFT 1836', 'SHOGUN NFT 2000',
    'SHOGUN NFT 2100'
);

-- 1.25% = 0.0125
UPDATE nfts SET daily_rate_limit = 0.0125 
WHERE name IN (
    'SHOGUN NFT 3000', 'SHOGUN NFT 3175', 'SHOGUN NFT 4000',
    'SHOGUN NFT 5000', 'SHOGUN NFT 6600', 'SHOGUN NFT 8000',
    'SHOGUN NFT 10000', 'SHOGUN NFT 1000 (Special)'
);

-- 1.5% = 0.015
UPDATE nfts SET daily_rate_limit = 0.015 
WHERE name = 'SHOGUN NFT 30000';

-- 2.0% = 0.020
UPDATE nfts SET daily_rate_limit = 0.020 
WHERE name = 'SHOGUN NFT 100000';

-- 4. NFTを正しいグループに分類
-- 0.5%グループ: SHOGUN NFT 100, 200
UPDATE nfts 
SET group_id = (
    SELECT id FROM daily_rate_groups WHERE daily_rate_limit = 0.005
)
WHERE price <= 200 AND (is_special IS NULL OR is_special = false);

-- 1.0%グループ: SHOGUN NFT 300, 500, 1000, 1200
UPDATE nfts 
SET group_id = (
    SELECT id FROM daily_rate_groups WHERE daily_rate_limit = 0.010
)
WHERE price > 200 AND price <= 2100 AND (is_special IS NULL OR is_special = false);

-- 1.25%グループ: SHOGUN NFT 3000, 5000, 10000
UPDATE nfts 
SET group_id = (
    SELECT id FROM daily_rate_groups WHERE daily_rate_limit = 0.0125
)
WHERE (price > 2100 AND price <= 10000 AND (is_special IS NULL OR is_special = false))
   OR is_special = true;

-- 2.0%グループ: SHOGUN NFT 30000, 100000
UPDATE nfts 
SET group_id = (
    SELECT id FROM daily_rate_groups WHERE daily_rate_limit = 0.020
)
WHERE price > 10000 AND (is_special IS NULL OR is_special = false);

-- 5. 修正後の分類状況を確認
SELECT 
    'Fixed Classification' as check_type,
    n.name,
    n.price,
    n.daily_rate_limit,
    n.is_special,
    drg.group_name,
    drg.daily_rate_limit as group_limit,
    'CLASSIFIED' as status
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.group_id = drg.id
ORDER BY n.price;

-- 6. グループ別NFT数を確認
SELECT 
    'Group Summary' as check_type,
    drg.group_name,
    drg.daily_rate_limit,
    COUNT(n.id) as nft_count,
    STRING_AGG(n.name, ', ' ORDER BY n.price) as nft_list
FROM daily_rate_groups drg
LEFT JOIN nfts n ON n.group_id = drg.id
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;

-- 7. 日利上限値の修正結果を確認
SELECT 
    'Daily Rate Limits Fixed' as check_type,
    name,
    price,
    daily_rate_limit,
    (daily_rate_limit * 100) as daily_rate_percentage,
    is_special
FROM nfts
ORDER BY price;
