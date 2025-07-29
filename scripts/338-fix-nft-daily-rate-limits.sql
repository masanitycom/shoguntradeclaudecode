-- NFTの日利上限を正しい値に修正

-- 現在の状況を確認
SELECT 
    name,
    price,
    daily_rate_limit,
    (daily_rate_limit * 100) as daily_rate_percent
FROM nfts 
WHERE name IN ('SHOGUN NFT 1000 (Special)', 'SHOGUN NFT 10000')
ORDER BY name;

-- SHOGUN NFT 1000 (Special) を 1.25% に修正
UPDATE nfts 
SET 
    daily_rate_limit = 0.0125,
    updated_at = NOW()
WHERE name = 'SHOGUN NFT 1000 (Special)';

-- SHOGUN NFT 10000 を 1.25% に修正  
UPDATE nfts 
SET 
    daily_rate_limit = 0.0125,
    updated_at = NOW()
WHERE name = 'SHOGUN NFT 10000';

-- 1.25%グループが存在するかチェック
SELECT * FROM daily_rate_groups WHERE daily_rate_limit = 0.0125;

-- 1.25%グループが存在しない場合は作成
INSERT INTO daily_rate_groups (
    group_name,
    daily_rate_limit,
    description,
    created_at,
    updated_at
)
SELECT 
    '1.25%グループ',
    0.0125,
    'SHOGUN NFT 1000 (Special), 10000の高リスクグループ',
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM daily_rate_groups WHERE daily_rate_limit = 0.0125
);

-- 修正後の確認
SELECT 
    name,
    price,
    daily_rate_limit,
    (daily_rate_limit * 100) as daily_rate_percent
FROM nfts 
WHERE name IN ('SHOGUN NFT 1000 (Special)', 'SHOGUN NFT 10000')
ORDER BY name;

-- 全グループの確認
SELECT 
    drg.group_name,
    drg.daily_rate_limit,
    (drg.daily_rate_limit * 100) as daily_rate_percent,
    COUNT(n.id) as nft_count
FROM daily_rate_groups drg
LEFT JOIN nfts n ON drg.daily_rate_limit = n.daily_rate_limit
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;

SELECT 'NFTの日利上限を修正しました' as status;
