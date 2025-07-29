-- 🚨 緊急修復: NFT運用開始日を週利設定期間に合わせる

-- 1. 現在の問題状況を確認
SELECT 
    '=== 修復前の状況 ===' as section,
    COUNT(*) as total_nfts,
    MIN(created_at::DATE) as earliest_operation_date,
    MAX(created_at::DATE) as latest_operation_date,
    COUNT(CASE WHEN created_at::DATE > '2025-03-24' THEN 1 END) as problem_nfts
FROM user_nfts 
WHERE is_active = true;

-- 2. 全てのNFTの運用開始日を2025-02-10に修正
UPDATE user_nfts 
SET created_at = '2025-02-10 00:00:00'::TIMESTAMP,
    updated_at = NOW()
WHERE is_active = true
AND created_at::DATE > '2025-03-24';

-- 3. purchase_dateカラムが存在する場合も修正
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_nfts' 
        AND column_name = 'purchase_date'
    ) THEN
        UPDATE user_nfts 
        SET purchase_date = '2025-02-10',
            updated_at = NOW()
        WHERE is_active = true
        AND (purchase_date IS NULL OR purchase_date > '2025-03-24');
    END IF;
END $$;

-- 4. current_investmentが0の場合、NFT価格を設定
UPDATE user_nfts 
SET current_investment = n.price,
    updated_at = NOW()
FROM nfts n
WHERE user_nfts.nft_id = n.id
AND user_nfts.is_active = true
AND (user_nfts.current_investment IS NULL OR user_nfts.current_investment = 0);

-- 5. max_earningが設定されていない場合、300%ルールで設定
UPDATE user_nfts 
SET max_earning = n.price * 3,
    updated_at = NOW()
FROM nfts n
WHERE user_nfts.nft_id = n.id
AND user_nfts.is_active = true
AND (user_nfts.max_earning IS NULL OR user_nfts.max_earning = 0);

-- 6. 修復結果の確認
SELECT 
    '=== 修復後の状況 ===' as section,
    COUNT(*) as total_nfts,
    MIN(created_at::DATE) as earliest_operation_date,
    MAX(created_at::DATE) as latest_operation_date,
    COUNT(CASE WHEN created_at::DATE <= '2025-03-24' THEN 1 END) as fixed_nfts,
    COUNT(CASE WHEN current_investment > 0 THEN 1 END) as nfts_with_investment,
    COUNT(CASE WHEN max_earning > 0 THEN 1 END) as nfts_with_max_earning
FROM user_nfts 
WHERE is_active = true;

-- 7. ユーザー別の修復状況確認
SELECT 
    '=== ユーザー別修復状況 ===' as section,
    u.name as user_name,
    COUNT(un.id) as nft_count,
    MIN(un.created_at::DATE) as earliest_operation_date,
    SUM(n.price) as total_investment,
    SUM(un.max_earning) as total_max_earning
FROM users u
JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
JOIN nfts n ON un.nft_id = n.id
WHERE u.is_admin = false
GROUP BY u.id, u.name
ORDER BY total_investment DESC
LIMIT 10;

SELECT '🚨 NFT運用開始日緊急修復完了' as status;
