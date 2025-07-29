-- 単位の不一致を修正する
-- 方法1: NFTの値をグループに合わせて小数値に変換
-- 方法2: グループの値をNFTに合わせてパーセント値に変換

-- まず現在の状況を確認
SELECT 
    'Current NFT Values' as check_type,
    name,
    price,
    daily_rate_limit,
    (daily_rate_limit * 100) as as_percentage
FROM nfts
ORDER BY price;

SELECT 
    'Current Group Values' as check_type,
    group_name,
    daily_rate_limit,
    (daily_rate_limit * 100) as as_percentage
FROM daily_rate_groups
ORDER BY daily_rate_limit;

-- 方法1を採用: NFTの値を小数値に変換（0.50 → 0.005）
UPDATE nfts SET daily_rate_limit = daily_rate_limit / 100;

-- 修正後の確認
SELECT 
    'Fixed NFT Values' as check_type,
    name,
    price,
    daily_rate_limit,
    (daily_rate_limit * 100) as as_percentage
FROM nfts
ORDER BY price;

-- NFTを正しいグループに分類
UPDATE nfts 
SET group_id = (
    SELECT id FROM daily_rate_groups WHERE daily_rate_limit = 0.005
)
WHERE daily_rate_limit = 0.005;

UPDATE nfts 
SET group_id = (
    SELECT id FROM daily_rate_groups WHERE daily_rate_limit = 0.010
)
WHERE daily_rate_limit = 0.010;

UPDATE nfts 
SET group_id = (
    SELECT id FROM daily_rate_groups WHERE daily_rate_limit = 0.0125
)
WHERE daily_rate_limit = 0.0125;

UPDATE nfts 
SET group_id = (
    SELECT id FROM daily_rate_groups WHERE daily_rate_limit = 0.015
)
WHERE daily_rate_limit = 0.015;

UPDATE nfts 
SET group_id = (
    SELECT id FROM daily_rate_groups WHERE daily_rate_limit = 0.020
)
WHERE daily_rate_limit = 0.020;

-- 分類結果を確認
SELECT 
    'Final Classification' as check_type,
    n.name,
    n.price,
    n.daily_rate_limit,
    (n.daily_rate_limit * 100) as nft_percentage,
    drg.group_name,
    (drg.daily_rate_limit * 100) as group_percentage,
    CASE 
        WHEN n.daily_rate_limit = drg.daily_rate_limit THEN 'MATCHED'
        ELSE 'MISMATCH'
    END as status
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.group_id = drg.id
ORDER BY n.price;

-- グループ別NFT数の確認
SELECT 
    'Group Summary' as check_type,
    drg.group_name,
    (drg.daily_rate_limit * 100) as percentage,
    COUNT(n.id) as nft_count,
    STRING_AGG(n.name, ', ' ORDER BY n.price) as nft_list
FROM daily_rate_groups drg
LEFT JOIN nfts n ON n.group_id = drg.id
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;
