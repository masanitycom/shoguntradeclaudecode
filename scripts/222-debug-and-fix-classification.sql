-- デバッグ用：現在のNFTの状態を詳細確認
SELECT 
    'Current NFT Status' as check_type,
    name,
    price,
    daily_rate_limit,
    (daily_rate_limit * 100) as percentage,
    group_id,
    is_special
FROM nfts 
ORDER BY price;

-- 各グループのIDを確認
SELECT 
    'Group IDs' as check_type,
    id,
    group_name,
    daily_rate_limit,
    (daily_rate_limit * 100) as percentage
FROM daily_rate_groups 
ORDER BY daily_rate_limit;

-- 強制的に正しい分類を実行
-- まず全てのNFTのgroup_idをクリア
UPDATE nfts SET group_id = NULL;

-- 0.5%グループ: SHOGUN NFT 100, 200
UPDATE nfts 
SET daily_rate_limit = 0.005,
    group_id = (SELECT id FROM daily_rate_groups WHERE group_name = '0.5%グループ')
WHERE name IN ('SHOGUN NFT 100', 'SHOGUN NFT 200');

-- 1.0%グループ: 300, 500, 600, 1000系, 1200
UPDATE nfts 
SET daily_rate_limit = 0.010,
    group_id = (SELECT id FROM daily_rate_groups WHERE group_name = '1.0%グループ')
WHERE name IN (
    'SHOGUN NFT 300', 'SHOGUN NFT 500', 'SHOGUN NFT 600',
    'SHOGUN NFT 1000', 'SHOGUN NFT 1000 (Special)',
    'SHOGUN NFT 1100', 'SHOGUN NFT 1177', 'SHOGUN NFT 1200',
    'SHOGUN NFT 1217', 'SHOGUN NFT 1227', 'SHOGUN NFT 1300',
    'SHOGUN NFT 1350', 'SHOGUN NFT 1500', 'SHOGUN NFT 1600',
    'SHOGUN NFT 1836', 'SHOGUN NFT 2000', 'SHOGUN NFT 2100'
);

-- 1.25%グループ: 3000以上10000まで
UPDATE nfts 
SET daily_rate_limit = 0.0125,
    group_id = (SELECT id FROM daily_rate_groups WHERE group_name = '1.25%グループ')
WHERE name IN (
    'SHOGUN NFT 3000', 'SHOGUN NFT 3175', 'SHOGUN NFT 4000',
    'SHOGUN NFT 5000', 'SHOGUN NFT 6600', 'SHOGUN NFT 8000',
    'SHOGUN NFT 10000'
);

-- 1.5%グループ: SHOGUN NFT 30000
UPDATE nfts 
SET daily_rate_limit = 0.015,
    group_id = (SELECT id FROM daily_rate_groups WHERE group_name = '1.5%グループ')
WHERE name = 'SHOGUN NFT 30000';

-- 2.0%グループ: SHOGUN NFT 100000
UPDATE nfts 
SET daily_rate_limit = 0.020,
    group_id = (SELECT id FROM daily_rate_groups WHERE group_name = '2.0%グループ')
WHERE name = 'SHOGUN NFT 100000';

-- 修正後の状態を確認
SELECT 
    'After Fix Classification' as check_type,
    n.name,
    n.price,
    (n.daily_rate_limit * 100) as nft_percentage,
    n.is_special,
    drg.group_name,
    (drg.daily_rate_limit * 100) as group_percentage,
    CASE 
        WHEN n.daily_rate_limit = drg.daily_rate_limit THEN 'MATCHED'
        ELSE 'MISMATCH'
    END as status
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.group_id = drg.id
ORDER BY n.price;

-- グループ別サマリー（修正後）
SELECT 
    'Final Group Summary' as check_type,
    drg.group_name,
    (drg.daily_rate_limit * 100) as percentage,
    COUNT(n.id) as nft_count,
    STRING_AGG(n.name, ', ' ORDER BY n.price) as nft_list
FROM daily_rate_groups drg
LEFT JOIN nfts n ON n.group_id = drg.id
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;

-- 未分類NFTチェック
SELECT 
    'Unclassified Check' as check_type,
    name,
    price,
    daily_rate_limit,
    group_id
FROM nfts 
WHERE group_id IS NULL;
