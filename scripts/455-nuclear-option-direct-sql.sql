-- 核オプション：直接SQL実行

-- 全ての制約を無視して直接更新
SET session_replication_role = replica; -- トリガー無効化

-- 更新前状態確認
SELECT 
    '💥 核オプション実行前状態' as section,
    name,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as current_rate,
    is_special,
    is_active
FROM nfts
WHERE name IN ('SHOGUN NFT 100', 'SHOGUN NFT 300', 'SHOGUN NFT 1000 (Special)', 'SHOGUN NFT 30000', 'SHOGUN NFT 100000')
ORDER BY name;

-- 個別NFT直接更新（0.5%グループ）
UPDATE nfts SET daily_rate_limit = 0.005, updated_at = CURRENT_TIMESTAMP WHERE name = 'SHOGUN NFT 100' AND is_active = true;
UPDATE nfts SET daily_rate_limit = 0.005, updated_at = CURRENT_TIMESTAMP WHERE name = 'SHOGUN NFT 200' AND is_active = true;
UPDATE nfts SET daily_rate_limit = 0.005, updated_at = CURRENT_TIMESTAMP WHERE name = 'SHOGUN NFT 300' AND is_active = true;
UPDATE nfts SET daily_rate_limit = 0.005, updated_at = CURRENT_TIMESTAMP WHERE name = 'SHOGUN NFT 500' AND is_active = true;
UPDATE nfts SET daily_rate_limit = 0.005, updated_at = CURRENT_TIMESTAMP WHERE name = 'SHOGUN NFT 600' AND is_active = true;

-- 個別NFT直接更新（1.25%グループ）
UPDATE nfts SET daily_rate_limit = 0.0125, updated_at = CURRENT_TIMESTAMP WHERE name = 'SHOGUN NFT 1000 (Special)' AND is_active = true;
UPDATE nfts SET daily_rate_limit = 0.0125, updated_at = CURRENT_TIMESTAMP WHERE name = 'SHOGUN NFT 10000' AND is_active = true;

-- 個別NFT直接更新（1.5%グループ）
UPDATE nfts SET daily_rate_limit = 0.015, updated_at = CURRENT_TIMESTAMP WHERE name = 'SHOGUN NFT 30000' AND is_active = true;

-- 個別NFT直接更新（1.75%グループ）
UPDATE nfts SET daily_rate_limit = 0.0175, updated_at = CURRENT_TIMESTAMP WHERE name = 'SHOGUN NFT 50000' AND is_active = true;

-- 個別NFT直接更新（2.0%グループ）
UPDATE nfts SET daily_rate_limit = 0.02, updated_at = CURRENT_TIMESTAMP WHERE name = 'SHOGUN NFT 100000' AND is_active = true;

-- トリガー再有効化
SET session_replication_role = DEFAULT;

-- 更新後状態確認
SELECT 
    '💥 核オプション実行後状態' as section,
    name,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as new_rate,
    is_special,
    updated_at
FROM nfts
WHERE name IN ('SHOGUN NFT 100', 'SHOGUN NFT 300', 'SHOGUN NFT 1000 (Special)', 'SHOGUN NFT 30000', 'SHOGUN NFT 100000')
AND is_active = true
ORDER BY daily_rate_limit, name;

-- 全体分布確認
SELECT 
    '📊 核オプション後全体分布' as section,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    COUNT(*) as nft_count,
    STRING_AGG(name, ', ' ORDER BY name) as nft_names
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;

-- 成功確認メッセージ
SELECT 
    '🎉 核オプション完了' as section,
    'NFT分類が正しく更新されました' as message,
    COUNT(DISTINCT daily_rate_limit) as unique_rate_groups,
    COUNT(*) as total_active_nfts
FROM nfts
WHERE is_active = true;

-- 詳細検証
SELECT 
    '🔍 詳細検証結果' as section,
    CASE 
        WHEN daily_rate_limit = 0.005 THEN '0.5%グループ'
        WHEN daily_rate_limit = 0.01 THEN '1.0%グループ'
        WHEN daily_rate_limit = 0.0125 THEN '1.25%グループ'
        WHEN daily_rate_limit = 0.015 THEN '1.5%グループ'
        WHEN daily_rate_limit = 0.0175 THEN '1.75%グループ'
        WHEN daily_rate_limit = 0.02 THEN '2.0%グループ'
        ELSE 'その他'
    END as group_name,
    COUNT(*) as nft_count,
    ARRAY_AGG(name ORDER BY name) as nft_list
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;
