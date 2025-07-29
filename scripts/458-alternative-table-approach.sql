-- 代替アプローチ：一時テーブル経由

-- 1. 現在の状態をバックアップ
CREATE TEMP TABLE nfts_backup AS 
SELECT * FROM nfts WHERE is_active = true;

-- 2. 新しい値でテンポラリテーブル作成
CREATE TEMP TABLE nfts_new_rates AS
SELECT 
    id,
    name,
    CASE 
        WHEN name IN ('SHOGUN NFT 100', 'SHOGUN NFT 200', 'SHOGUN NFT 300', 'SHOGUN NFT 500', 'SHOGUN NFT 600') THEN 0.005
        WHEN name IN ('SHOGUN NFT 1000 (Special)', 'SHOGUN NFT 10000') THEN 0.0125
        WHEN name = 'SHOGUN NFT 30000' THEN 0.015
        WHEN name = 'SHOGUN NFT 50000' THEN 0.0175
        WHEN name = 'SHOGUN NFT 100000' THEN 0.02
        ELSE 0.01
    END as new_daily_rate_limit
FROM nfts 
WHERE is_active = true;

-- 3. 新しい値を表示
SELECT 
    '🎯 新しい値計画' as section,
    name,
    new_daily_rate_limit,
    (new_daily_rate_limit * 100) || '%' as new_rate
FROM nfts_new_rates
WHERE name IN ('SHOGUN NFT 100', 'SHOGUN NFT 300', 'SHOGUN NFT 1000 (Special)', 'SHOGUN NFT 30000', 'SHOGUN NFT 100000')
ORDER BY new_daily_rate_limit, name;

-- 4. JOINを使った一括更新
UPDATE nfts 
SET 
    daily_rate_limit = nr.new_daily_rate_limit,
    updated_at = CURRENT_TIMESTAMP
FROM nfts_new_rates nr
WHERE nfts.id = nr.id
AND nfts.is_active = true;

-- 5. 結果確認
SELECT 
    '🔄 JOIN更新結果' as section,
    name,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as final_rate,
    updated_at
FROM nfts
WHERE name IN ('SHOGUN NFT 100', 'SHOGUN NFT 300', 'SHOGUN NFT 1000 (Special)', 'SHOGUN NFT 30000', 'SHOGUN NFT 100000')
AND is_active = true
ORDER BY daily_rate_limit, name;

-- 6. 最終分布確認
SELECT 
    '📊 最終分布確認' as section,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    COUNT(*) as nft_count,
    STRING_AGG(name, ', ' ORDER BY name) as nft_names
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;

-- 7. 成功判定
SELECT 
    '🎉 成功判定' as section,
    CASE 
        WHEN COUNT(DISTINCT daily_rate_limit) >= 5 THEN '✅ 成功：複数グループに分散'
        ELSE '❌ 失敗：まだ分散されていない'
    END as result,
    COUNT(DISTINCT daily_rate_limit) as unique_groups,
    COUNT(*) as total_nfts
FROM nfts
WHERE is_active = true;
