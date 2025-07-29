-- CSVデータに基づく正しいNFT分類
-- 仕様書とCSVデータを参照して正確に分類

-- 1. 現在の状況を確認
SELECT 'Before Classification' as status, COUNT(*) as total_nfts FROM nfts;

-- 2. NFTの日利上限値を正しく設定（CSVデータに基づく）
-- 0.5%グループ (0.005): SHOGUN NFT 100, 200
UPDATE nfts SET daily_rate_limit = 0.005 
WHERE name IN ('SHOGUN NFT 100', 'SHOGUN NFT 200');

-- 1.0%グループ (0.010): SHOGUN NFT 300, 500, 600, 1000, 1100, 1177, 1200, 1217, 1227, 1300, 1350, 1500, 1600, 1836, 2000, 2100
UPDATE nfts SET daily_rate_limit = 0.010 
WHERE name IN (
    'SHOGUN NFT 300', 'SHOGUN NFT 500', 'SHOGUN NFT 600',
    'SHOGUN NFT 1000', 'SHOGUN NFT 1100', 'SHOGUN NFT 1177',
    'SHOGUN NFT 1200', 'SHOGUN NFT 1217', 'SHOGUN NFT 1227',
    'SHOGUN NFT 1300', 'SHOGUN NFT 1350', 'SHOGUN NFT 1500',
    'SHOGUN NFT 1600', 'SHOGUN NFT 1836', 'SHOGUN NFT 2000',
    'SHOGUN NFT 2100'
);

-- 1.25%グループ (0.0125): SHOGUN NFT 3000, 3175, 4000, 5000, 6600, 8000, 10000
UPDATE nfts SET daily_rate_limit = 0.0125 
WHERE name IN (
    'SHOGUN NFT 3000', 'SHOGUN NFT 3175', 'SHOGUN NFT 4000',
    'SHOGUN NFT 5000', 'SHOGUN NFT 6600', 'SHOGUN NFT 8000',
    'SHOGUN NFT 10000'
);

-- 1.5%グループ (0.015): SHOGUN NFT 30000
UPDATE nfts SET daily_rate_limit = 0.015 
WHERE name = 'SHOGUN NFT 30000';

-- 2.0%グループ (0.020): SHOGUN NFT 100000
UPDATE nfts SET daily_rate_limit = 0.020 
WHERE name = 'SHOGUN NFT 100000';

-- 特別NFT (1.0%グループに統一): SHOGUN NFT 1000 (Special)
UPDATE nfts SET daily_rate_limit = 0.010 
WHERE name = 'SHOGUN NFT 1000 (Special)';

-- 3. 1.5%グループが存在しない場合は作成
INSERT INTO daily_rate_groups (group_name, daily_rate_limit, description)
VALUES ('1.5%グループ', 0.015, 'SHOGUN NFT 30000のプレミアムグループ')
ON CONFLICT (group_name) DO NOTHING;

-- 4. NFTを正しいグループに分類（日利上限値で完全一致）
-- 0.5%グループ
UPDATE nfts 
SET group_id = (SELECT id FROM daily_rate_groups WHERE daily_rate_limit = 0.005)
WHERE daily_rate_limit = 0.005;

-- 1.0%グループ
UPDATE nfts 
SET group_id = (SELECT id FROM daily_rate_groups WHERE daily_rate_limit = 0.010)
WHERE daily_rate_limit = 0.010;

-- 1.25%グループ
UPDATE nfts 
SET group_id = (SELECT id FROM daily_rate_groups WHERE daily_rate_limit = 0.0125)
WHERE daily_rate_limit = 0.0125;

-- 1.5%グループ
UPDATE nfts 
SET group_id = (SELECT id FROM daily_rate_groups WHERE daily_rate_limit = 0.015)
WHERE daily_rate_limit = 0.015;

-- 2.0%グループ
UPDATE nfts 
SET group_id = (SELECT id FROM daily_rate_groups WHERE daily_rate_limit = 0.020)
WHERE daily_rate_limit = 0.020;

-- 5. 分類結果を確認
SELECT 
    'Final Classification' as check_type,
    n.name,
    n.price,
    (n.daily_rate_limit * 100) as daily_rate_percentage,
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

-- 6. グループ別サマリー
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

-- 7. 分類されていないNFTがないかチェック
SELECT 
    'Unclassified NFTs' as check_type,
    name,
    price,
    daily_rate_limit,
    'NO GROUP ASSIGNED' as issue
FROM nfts 
WHERE group_id IS NULL;

-- 8. 利用可能なグループ一覧
SELECT 
    'Available Groups' as check_type,
    group_name,
    (daily_rate_limit * 100) as percentage,
    description
FROM daily_rate_groups 
ORDER BY daily_rate_limit;
