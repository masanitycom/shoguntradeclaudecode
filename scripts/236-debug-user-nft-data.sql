-- オオタキヨジのNFTデータを詳細に調査

-- 1. ユーザー情報を確認
SELECT 
    'User Info' as check_type,
    id,
    name,
    email,
    user_id
FROM users 
WHERE email = 'kiyoji1948@gmail.com';

-- 2. user_nftsテーブルでNFTを確認
SELECT 
    'User NFTs' as check_type,
    un.id,
    un.user_id,
    un.nft_id,
    un.current_investment,
    un.total_earned,
    un.max_earning,
    un.is_active,
    un.created_at
FROM user_nfts un
JOIN users u ON u.id = un.user_id
WHERE u.email = 'kiyoji1948@gmail.com';

-- 3. NFT詳細情報を確認
SELECT 
    'NFT Details' as check_type,
    n.id,
    n.name,
    n.price,
    n.daily_rate_limit,
    n.is_special
FROM nfts n
JOIN user_nfts un ON un.nft_id = n.id
JOIN users u ON u.id = un.user_id
WHERE u.email = 'kiyoji1948@gmail.com';

-- 4. 結合クエリで完全な情報を確認
SELECT 
    'Complete NFT Info' as check_type,
    u.name as user_name,
    u.email,
    n.name as nft_name,
    n.price as nft_price,
    un.current_investment,
    un.total_earned,
    un.is_active,
    un.created_at
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON n.id = un.nft_id
WHERE u.email = 'kiyoji1948@gmail.com'
ORDER BY un.created_at DESC;

-- 5. アクティブなNFTのみ確認
SELECT 
    'Active NFTs Only' as check_type,
    u.name as user_name,
    n.name as nft_name,
    n.price as nft_price,
    un.current_investment,
    un.total_earned,
    un.is_active
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON n.id = un.nft_id
WHERE u.email = 'kiyoji1948@gmail.com'
AND un.is_active = true;

-- 6. 全ユーザーのNFT保有状況を確認（比較用）
SELECT 
    'All Users NFT Summary' as check_type,
    u.name,
    u.email,
    COUNT(un.id) as nft_count,
    SUM(n.price) as total_investment,
    SUM(un.total_earned) as total_earned
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
LEFT JOIN nfts n ON n.id = un.nft_id
GROUP BY u.id, u.name, u.email
ORDER BY total_investment DESC NULLS LAST;
