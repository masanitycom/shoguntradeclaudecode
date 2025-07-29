-- 最終手段：テーブル再構築で確実に修正

-- 1. 現在の状態を完全バックアップ
CREATE TABLE nfts_complete_backup AS 
SELECT * FROM nfts;

-- 2. 正しい値を持つ新しいテーブルを作成
CREATE TABLE nfts_corrected AS
SELECT 
    id,
    name,
    description,
    price,
    CASE 
        -- 0.5%グループ (特別NFT: 100,200,600 + 通常NFT: 300,500)
        WHEN (name = 'SHOGUN NFT 100' AND is_special = true) THEN 0.005
        WHEN (name = 'SHOGUN NFT 200' AND is_special = true) THEN 0.005
        WHEN (name = 'SHOGUN NFT 600' AND is_special = true) THEN 0.005
        WHEN (name = 'SHOGUN NFT 300' AND is_special = false) THEN 0.005
        WHEN (name = 'SHOGUN NFT 500' AND is_special = false) THEN 0.005
        
        -- 1.25%グループ (特別NFT: 1000 + 通常NFT: 10000)
        WHEN (name = 'SHOGUN NFT 1000 (Special)' AND is_special = true) THEN 0.0125
        WHEN (name = 'SHOGUN NFT 10000' AND is_special = false) THEN 0.0125
        
        -- 1.5%グループ (通常NFT: 30000)
        WHEN (name = 'SHOGUN NFT 30000' AND is_special = false) THEN 0.015
        
        -- 1.75%グループ (通常NFT: 50000)
        WHEN (name = 'SHOGUN NFT 50000' AND is_special = false) THEN 0.0175
        
        -- 2.0%グループ (通常NFT: 100000)
        WHEN (name = 'SHOGUN NFT 100000' AND is_special = false) THEN 0.02
        
        -- 1.0%グループ (その他全て)
        ELSE 0.01
    END as daily_rate_limit,
    is_special,
    is_active,
    image_url,
    CURRENT_TIMESTAMP as created_at,
    CURRENT_TIMESTAMP as updated_at
FROM nfts
WHERE is_active = true;

-- 3. 修正されたデータを確認
SELECT 
    '🎯 修正データ確認' as section,
    name,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate,
    is_special
FROM nfts_corrected
WHERE name IN ('SHOGUN NFT 100', 'SHOGUN NFT 300', 'SHOGUN NFT 1000 (Special)', 'SHOGUN NFT 30000', 'SHOGUN NFT 100000')
ORDER BY daily_rate_limit, name;

-- 4. 分布確認
SELECT 
    '📊 修正後分布' as section,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    COUNT(*) as nft_count,
    STRING_AGG(name, ', ' ORDER BY name) as nft_names
FROM nfts_corrected
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;

-- 5. 元のテーブルを削除して新しいテーブルをリネーム
DROP TABLE nfts CASCADE;
ALTER TABLE nfts_corrected RENAME TO nfts;

-- 6. 必要な制約とインデックスを再作成
ALTER TABLE nfts ADD CONSTRAINT nfts_pkey PRIMARY KEY (id);
ALTER TABLE nfts ADD CONSTRAINT nfts_name_key UNIQUE (name);
CREATE INDEX idx_nfts_active ON nfts(is_active);
CREATE INDEX idx_nfts_special ON nfts(is_special);
CREATE INDEX idx_nfts_daily_rate ON nfts(daily_rate_limit);

-- 7. 最終確認
SELECT 
    '🎉 最終確認' as section,
    name,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as final_rate,
    is_special,
    updated_at
FROM nfts
WHERE name IN ('SHOGUN NFT 100', 'SHOGUN NFT 300', 'SHOGUN NFT 1000 (Special)', 'SHOGUN NFT 30000', 'SHOGUN NFT 100000')
ORDER BY daily_rate_limit, name;

-- 8. 成功判定
SELECT 
    '✅ 成功判定' as section,
    CASE 
        WHEN COUNT(DISTINCT daily_rate_limit) >= 5 THEN '🎉 成功：NFTが正しく分散されました！'
        ELSE '❌ 失敗：まだ分散されていません'
    END as result,
    COUNT(DISTINCT daily_rate_limit) as unique_groups,
    COUNT(*) as total_nfts
FROM nfts
WHERE is_active = true;
