-- NFTの正しいグループ分類を修正
-- エラー修正: group_idカラムを使用

-- 1. まず現在のテーブル構造を確認
SELECT 
    'NFT Table Structure' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'nfts' 
ORDER BY ordinal_position;

-- 2. 現在の分類状況を確認
SELECT 
    'Current Classification' as check_type,
    n.name,
    n.price,
    n.daily_rate_limit,
    n.group_id,
    drg.group_name,
    drg.daily_rate_limit as group_limit
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.group_id = drg.id
ORDER BY n.price;

-- 3. 正しいグループIDを取得して確認
SELECT 
    'Available Groups' as check_type,
    id,
    group_name,
    daily_rate_limit,
    description
FROM daily_rate_groups 
ORDER BY daily_rate_limit;

-- 4. NFTを価格に基づいて正しいグループに分類
-- 0.5%グループ: SHOGUN NFT 100, 200
UPDATE nfts 
SET group_id = (
    SELECT id FROM daily_rate_groups WHERE daily_rate_limit = 0.005
)
WHERE price <= 200 AND type = 'normal';

-- 1.0%グループ: SHOGUN NFT 300, 500, 1000, 1200
UPDATE nfts 
SET group_id = (
    SELECT id FROM daily_rate_groups WHERE daily_rate_limit = 0.010
)
WHERE price > 200 AND price <= 1200 AND type = 'normal';

-- 1.25%グループ: SHOGUN NFT 3000, 5000, 10000
UPDATE nfts 
SET group_id = (
    SELECT id FROM daily_rate_groups WHERE daily_rate_limit = 0.0125
)
WHERE price > 1200 AND price <= 10000 AND type = 'normal';

-- 2.0%グループ: SHOGUN NFT 30000, 100000
UPDATE nfts 
SET group_id = (
    SELECT id FROM daily_rate_groups WHERE daily_rate_limit = 0.020
)
WHERE price > 10000 AND type = 'normal';

-- 特別NFTは1.25%グループに設定
UPDATE nfts 
SET group_id = (
    SELECT id FROM daily_rate_groups WHERE daily_rate_limit = 0.0125
)
WHERE type = 'special';

-- 5. 修正後の分類状況を確認
SELECT 
    'Fixed Classification' as check_type,
    n.name,
    n.price,
    n.type,
    n.daily_rate_limit,
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
