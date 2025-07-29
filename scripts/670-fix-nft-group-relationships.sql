-- NFTとグループの関連修正

-- 1. 現在のNFTの状況を確認
SELECT 
    id,
    name,
    price,
    daily_rate_limit,
    is_active
FROM nfts 
ORDER BY price;

-- 2. NFTの日利上限を価格に基づいて正しく設定
UPDATE nfts SET daily_rate_limit = 0.5 WHERE price <= 100;
UPDATE nfts SET daily_rate_limit = 1.0 WHERE price > 100 AND price <= 300;
UPDATE nfts SET daily_rate_limit = 1.25 WHERE price > 300 AND price <= 500;
UPDATE nfts SET daily_rate_limit = 1.5 WHERE price > 500 AND price <= 1000;
UPDATE nfts SET daily_rate_limit = 1.75 WHERE price > 1000 AND price <= 1500;
UPDATE nfts SET daily_rate_limit = 2.0 WHERE price > 1500;

-- 3. 特別NFTの個別設定
UPDATE nfts SET daily_rate_limit = 1.5 WHERE name LIKE '%Special%';

-- 4. daily_rate_groupsテーブルの制約を確認・作成
-- まず既存の制約を確認
SELECT constraint_name, constraint_type 
FROM information_schema.table_constraints 
WHERE table_name = 'daily_rate_groups';

-- 5. UNIQUE制約が存在しない場合は作成
ALTER TABLE daily_rate_groups 
ADD CONSTRAINT IF NOT EXISTS daily_rate_groups_daily_rate_limit_key 
UNIQUE (daily_rate_limit);

-- 6. 基本グループを安全に挿入
INSERT INTO daily_rate_groups (daily_rate_limit, group_name) 
SELECT 0.5, '0.5%グループ'
WHERE NOT EXISTS (SELECT 1 FROM daily_rate_groups WHERE daily_rate_limit = 0.5);

INSERT INTO daily_rate_groups (daily_rate_limit, group_name) 
SELECT 1.0, '1.0%グループ'
WHERE NOT EXISTS (SELECT 1 FROM daily_rate_groups WHERE daily_rate_limit = 1.0);

INSERT INTO daily_rate_groups (daily_rate_limit, group_name) 
SELECT 1.25, '1.25%グループ'
WHERE NOT EXISTS (SELECT 1 FROM daily_rate_groups WHERE daily_rate_limit = 1.25);

INSERT INTO daily_rate_groups (daily_rate_limit, group_name) 
SELECT 1.5, '1.5%グループ'
WHERE NOT EXISTS (SELECT 1 FROM daily_rate_groups WHERE daily_rate_limit = 1.5);

INSERT INTO daily_rate_groups (daily_rate_limit, group_name) 
SELECT 1.75, '1.75%グループ'
WHERE NOT EXISTS (SELECT 1 FROM daily_rate_groups WHERE daily_rate_limit = 1.75);

INSERT INTO daily_rate_groups (daily_rate_limit, group_name) 
SELECT 2.0, '2.0%グループ'
WHERE NOT EXISTS (SELECT 1 FROM daily_rate_groups WHERE daily_rate_limit = 2.0);

-- 7. 修正結果を確認
SELECT 
    n.id,
    n.name,
    n.price,
    n.daily_rate_limit,
    CASE 
        WHEN n.price <= 100 THEN '0.5%グループ'
        WHEN n.price <= 300 THEN '1.0%グループ'
        WHEN n.price <= 500 THEN '1.25%グループ'
        WHEN n.price <= 1000 THEN '1.5%グループ'
        WHEN n.price <= 1500 THEN '1.75%グループ'
        ELSE '2.0%グループ'
    END as calculated_group,
    COUNT(un.id) as user_count
FROM nfts n
LEFT JOIN user_nfts un ON n.id = un.nft_id AND un.is_active = true
GROUP BY n.id, n.name, n.price, n.daily_rate_limit
ORDER BY n.price;
