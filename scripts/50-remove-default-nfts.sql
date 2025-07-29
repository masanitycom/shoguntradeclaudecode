-- デフォルトで付与されたNFTを削除し、紹介関係のみ修正

-- 現在の状況確認
SELECT 'current_status' as step;

SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN is_admin = false THEN 1 END) as regular_users,
    COUNT(CASE WHEN is_admin = true THEN 1 END) as admin_users
FROM users;

SELECT 
    COUNT(*) as total_user_nfts,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_nfts
FROM user_nfts;

-- マイグレーション時に自動付与されたNFTを削除
DELETE FROM user_nfts 
WHERE created_at >= '2024-01-01' -- マイグレーション以降に作成されたもの
AND user_id IN (
    SELECT id FROM users WHERE is_admin = false
);

-- 削除結果確認
SELECT 'after_cleanup' as step;

SELECT 
    COUNT(*) as remaining_user_nfts,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_nfts
FROM user_nfts;

-- ユーザー別NFT保有状況
SELECT 
    u.user_id,
    u.name,
    u.email,
    COUNT(un.id) as nft_count,
    COALESCE(SUM(un.current_investment), 0) as total_investment
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE u.is_admin = false
GROUP BY u.id, u.user_id, u.name, u.email
ORDER BY u.created_at;

SELECT 'デフォルトNFT削除完了' AS result;
