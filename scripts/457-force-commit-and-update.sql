-- 強制コミット付きUPDATE

-- トランザクション外で実行
COMMIT;

-- 個別UPDATE（トランザクション外）
UPDATE nfts SET daily_rate_limit = 0.005, updated_at = CURRENT_TIMESTAMP WHERE name = 'SHOGUN NFT 100' AND is_active = true;
COMMIT;

UPDATE nfts SET daily_rate_limit = 0.005, updated_at = CURRENT_TIMESTAMP WHERE name = 'SHOGUN NFT 200' AND is_active = true;
COMMIT;

UPDATE nfts SET daily_rate_limit = 0.005, updated_at = CURRENT_TIMESTAMP WHERE name = 'SHOGUN NFT 300' AND is_active = true;
COMMIT;

UPDATE nfts SET daily_rate_limit = 0.005, updated_at = CURRENT_TIMESTAMP WHERE name = 'SHOGUN NFT 500' AND is_active = true;
COMMIT;

UPDATE nfts SET daily_rate_limit = 0.005, updated_at = CURRENT_TIMESTAMP WHERE name = 'SHOGUN NFT 600' AND is_active = true;
COMMIT;

UPDATE nfts SET daily_rate_limit = 0.0125, updated_at = CURRENT_TIMESTAMP WHERE name = 'SHOGUN NFT 1000 (Special)' AND is_active = true;
COMMIT;

UPDATE nfts SET daily_rate_limit = 0.0125, updated_at = CURRENT_TIMESTAMP WHERE name = 'SHOGUN NFT 10000' AND is_active = true;
COMMIT;

UPDATE nfts SET daily_rate_limit = 0.015, updated_at = CURRENT_TIMESTAMP WHERE name = 'SHOGUN NFT 30000' AND is_active = true;
COMMIT;

UPDATE nfts SET daily_rate_limit = 0.0175, updated_at = CURRENT_TIMESTAMP WHERE name = 'SHOGUN NFT 50000' AND is_active = true;
COMMIT;

UPDATE nfts SET daily_rate_limit = 0.02, updated_at = CURRENT_TIMESTAMP WHERE name = 'SHOGUN NFT 100000' AND is_active = true;
COMMIT;

-- 結果確認
SELECT 
    '💪 強制更新結果' as section,
    name,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as new_rate,
    updated_at
FROM nfts
WHERE name IN ('SHOGUN NFT 100', 'SHOGUN NFT 300', 'SHOGUN NFT 1000 (Special)', 'SHOGUN NFT 30000', 'SHOGUN NFT 100000')
AND is_active = true
ORDER BY daily_rate_limit, name;

-- 全体分布
SELECT 
    '📊 強制更新後分布' as section,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    COUNT(*) as nft_count
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;
