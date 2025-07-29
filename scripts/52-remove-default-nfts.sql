-- デフォルトで付与されたNFTを削除

SELECT 'removing_default_nfts' as step;

-- 現在のNFT保有状況を確認
SELECT 
    'current_nft_status' as info,
    COUNT(*) as total_user_nfts,
    COUNT(DISTINCT user_id) as users_with_nfts,
    AVG(current_investment) as avg_investment
FROM user_nfts 
WHERE is_active = true;

-- デフォルトで付与されたNFTを削除
-- （マイグレーション時に自動付与されたもの）
DELETE FROM user_nfts 
WHERE is_active = true 
AND created_at BETWEEN '2024-01-01' AND NOW()
AND current_investment IN (300, 500, 1000, 3000, 5000); -- 一般的なNFT価格

-- 削除後の状況確認
SELECT 
    'after_cleanup' as info,
    COUNT(*) as remaining_user_nfts,
    COUNT(DISTINCT user_id) as users_with_nfts,
    COALESCE(AVG(current_investment), 0) as avg_investment
FROM user_nfts 
WHERE is_active = true;

SELECT 'デフォルトNFT削除完了' AS result;
