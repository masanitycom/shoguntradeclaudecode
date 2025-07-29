-- マイグレーション状況の詳細確認

-- 1. NFTを持たないユーザーが残っているか確認
SELECT 'NFT未保有ユーザーの詳細' as check_type;

SELECT 
    u.id,
    u.user_id,
    u.name,
    u.email,
    u.is_admin,
    u.created_at
FROM users u 
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true 
WHERE un.id IS NULL 
ORDER BY u.created_at
LIMIT 10;

-- 2. NFT未保有ユーザーの総数
SELECT 
    'NFT未保有ユーザー数（管理者含む）' as type, 
    COUNT(*) as count 
FROM users u 
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true 
WHERE un.id IS NULL;

-- 3. NFT未保有ユーザー数（管理者除く）
SELECT 
    'NFT未保有ユーザー数（管理者除く）' as type, 
    COUNT(*) as count 
FROM users u 
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true 
WHERE un.id IS NULL AND u.is_admin = false;

-- 4. 利用可能なNFTがあるか確認
SELECT '利用可能NFT確認' as check_type;
SELECT id, name, price, is_special, is_active FROM nfts WHERE is_active = true ORDER BY price;

-- 5. 最近作成されたuser_nftsレコードを確認
SELECT '最近のuser_nfts作成状況' as check_type;
SELECT 
    un.*,
    u.name as user_name,
    n.name as nft_name
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.created_at > NOW() - INTERVAL '1 hour'
ORDER BY un.created_at DESC
LIMIT 5;

-- 6. マイグレーション対象ユーザーが実際に存在するか確認
SELECT 'マイグレーション対象ユーザー存在確認' as check_type;
SELECT COUNT(*) as target_user_count
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE un.id IS NULL AND u.is_admin = false;
