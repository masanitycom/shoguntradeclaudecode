-- オオタキヨジのNFT状況を詳細調査

-- 1. オオタキヨジのuser_nftsテーブル確認
SELECT 
    'オオタキヨジ user_nfts' as check_type,
    un.*
FROM user_nfts un
JOIN users u ON u.id = un.user_id
WHERE u.email = 'kiyoji1948@gmail.com';

-- 2. オオタキヨジのNFT購入申請確認
SELECT 
    'オオタキヨジ NFT購入申請' as check_type,
    npa.*
FROM nft_purchase_applications npa
JOIN users u ON u.id = npa.user_id
WHERE u.email = 'kiyoji1948@gmail.com';

-- 3. 他のユーザーのNFTデータ構造確認（比較用）
SELECT 
    '他ユーザーNFT構造' as check_type,
    un.id,
    un.user_id,
    un.nft_id,
    un.current_investment,
    un.total_earned,
    un.max_earning,
    un.is_active,
    n.name as nft_name,
    n.price as nft_price,
    u.name as user_name
FROM user_nfts un
JOIN users u ON u.id = un.user_id
JOIN nfts n ON n.id = un.nft_id
WHERE u.email = 'iwanedenki@gmail.com'  -- NFTを持っているユーザーの例
LIMIT 5;

-- 4. NFTテーブルの構造確認
SELECT 
    'NFTテーブル構造' as check_type,
    id,
    name,
    price,
    daily_rate_limit,
    is_special,
    is_active
FROM nfts
WHERE name LIKE '%SHOGUN%'
ORDER BY price DESC;
