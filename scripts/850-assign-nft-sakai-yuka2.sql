-- サカイユカ2さんにNFT付与

SELECT '=== サカイユカ2さんNFT付与 ===' as section;

-- 1. サカイユカ2さんの情報確認
SELECT 'サカイユカ2さん情報:' as user_info;
SELECT 
    id,
    name,
    user_id,
    email
FROM users
WHERE name = 'サカイユカ2'
  AND user_id = 'ys8788'
  AND email = 'E@shogun-trade.com';

-- 2. 既存NFT確認
SELECT '既存NFT確認:' as existing_nfts;
SELECT 
    un.id,
    n.name as nft_name,
    un.is_active
FROM user_nfts un
JOIN nfts n ON un.nft_id = n.id
JOIN users u ON un.user_id = u.id
WHERE u.name = 'サカイユカ2'
  AND u.user_id = 'ys8788';

-- 3. SHOGUN NFT 1000の情報
SELECT 'NFT情報:' as nft_info;
SELECT 
    id,
    name,
    price,
    daily_rate_limit
FROM nfts
WHERE name = 'SHOGUN NFT 1000'
  AND is_active = true;

-- 4. NFT付与実行
SELECT 'サカイユカ2さんにNFT付与中...' as assignment;
INSERT INTO user_nfts (
    user_id,
    nft_id,
    purchase_date,
    purchase_price,
    current_investment,
    max_earning,
    total_earned,
    is_active
) 
SELECT 
    u.id as user_id,
    n.id as nft_id,
    '2025-02-03'::timestamp with time zone as purchase_date,
    n.price as purchase_price,
    n.price as current_investment,
    n.price * 3 as max_earning,
    0.00 as total_earned,
    true as is_active
FROM users u, nfts n
WHERE u.name = 'サカイユカ2'
  AND u.user_id = 'ys8788'
  AND u.email = 'E@shogun-trade.com'
  AND n.name = 'SHOGUN NFT 1000'
  AND n.is_active = true;

-- 5. 付与結果確認
SELECT 'NFT付与結果確認:' as result;
SELECT 
    u.name as user_name,
    u.user_id,
    u.email,
    n.name as nft_name,
    un.purchase_price,
    un.current_investment,
    un.max_earning,
    un.purchase_date,
    un.is_active,
    un.created_at
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.name = 'サカイユカ2'
  AND u.user_id = 'ys8788'
  AND u.email = 'E@shogun-trade.com'
ORDER BY un.created_at DESC
LIMIT 1;

SELECT '=== サカイユカ2さんNFT付与完了 ===' as status;