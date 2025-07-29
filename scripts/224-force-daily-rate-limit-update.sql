-- 強制的に日利上限値を正しく更新

-- 1. 現在の状況を確認
SELECT 'Before Force Update' as status, name, daily_rate_limit, group_id FROM nfts ORDER BY price;

-- 2. 個別に強制更新（確実に実行されるよう）

-- 0.5%グループ（SHOGUN NFT 100, 200）
UPDATE nfts SET daily_rate_limit = 0.005 WHERE name = 'SHOGUN NFT 100';
UPDATE nfts SET daily_rate_limit = 0.005 WHERE name = 'SHOGUN NFT 200';

-- 1.25%グループ（高額NFT）
UPDATE nfts SET daily_rate_limit = 0.0125 WHERE name = 'SHOGUN NFT 3000';
UPDATE nfts SET daily_rate_limit = 0.0125 WHERE name = 'SHOGUN NFT 3175';
UPDATE nfts SET daily_rate_limit = 0.0125 WHERE name = 'SHOGUN NFT 4000';
UPDATE nfts SET daily_rate_limit = 0.0125 WHERE name = 'SHOGUN NFT 5000';
UPDATE nfts SET daily_rate_limit = 0.0125 WHERE name = 'SHOGUN NFT 6600';
UPDATE nfts SET daily_rate_limit = 0.0125 WHERE name = 'SHOGUN NFT 8000';
UPDATE nfts SET daily_rate_limit = 0.0125 WHERE name = 'SHOGUN NFT 10000';

-- 1.5%グループ（SHOGUN NFT 30000）
UPDATE nfts SET daily_rate_limit = 0.015 WHERE name = 'SHOGUN NFT 30000';

-- 3. 更新後の確認
SELECT 'After Force Update' as status, name, daily_rate_limit, group_id FROM nfts ORDER BY price;

-- 4. 最終検証
SELECT 
    'Final Verification' as check_type,
    n.name,
    n.price,
    (n.daily_rate_limit * 100) as nft_percentage,
    n.is_special,
    drg.group_name,
    (drg.daily_rate_limit * 100) as group_percentage,
    CASE 
        WHEN ABS(n.daily_rate_limit - drg.daily_rate_limit) < 0.0001 THEN '✅ PERFECT MATCH'
        ELSE '❌ MISMATCH'
    END as status
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.group_id = drg.id
ORDER BY n.price;

-- 5. 問題があるNFTを特定
SELECT 
    'Problem NFTs' as check_type,
    n.name,
    n.daily_rate_limit as nft_rate,
    drg.daily_rate_limit as group_rate,
    'NEEDS MANUAL FIX' as action
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.group_id = drg.id
WHERE ABS(n.daily_rate_limit - drg.daily_rate_limit) >= 0.0001;

-- 6. 完璧な分類の確認
SELECT 
    'Perfect Classification Count' as check_type,
    COUNT(*) as total_nfts,
    COUNT(CASE WHEN ABS(n.daily_rate_limit - drg.daily_rate_limit) < 0.0001 THEN 1 END) as perfect_matches,
    COUNT(CASE WHEN ABS(n.daily_rate_limit - drg.daily_rate_limit) >= 0.0001 THEN 1 END) as mismatches
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.group_id = drg.id;
