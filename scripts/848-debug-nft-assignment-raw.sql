-- NFT付与のテストを直接SQLで実行

SELECT '=== NFT付与デバッグ ===' as section;

-- 1. テスト用ユーザーとNFTを確認
SELECT 'テスト対象ユーザー:' as target_user;
SELECT 
    id,
    name,
    user_id,
    email
FROM users
WHERE name = 'サカイユカ3'
  AND user_id = 'ys0888'
LIMIT 1;

-- 2. 利用可能なNFT確認
SELECT 'テスト用NFT:' as target_nft;
SELECT 
    id,
    name,
    price,
    daily_rate_limit,
    is_special,
    is_active
FROM nfts
WHERE name = 'SHOGUN NFT 1000'
  AND is_active = true
LIMIT 1;

-- 3. 直接INSERT実行テスト
SELECT 'NFT付与テスト実行:' as insert_test;
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
WHERE u.name = 'サカイユカ3'
  AND u.user_id = 'ys0888'
  AND n.name = 'SHOGUN NFT 1000'
  AND n.is_active = true
LIMIT 1;

-- 4. 結果確認
SELECT 'NFT付与結果確認:' as result_check;
SELECT 
    un.id,
    u.name as user_name,
    u.user_id,
    n.name as nft_name,
    un.purchase_price,
    un.current_investment,
    un.max_earning,
    un.purchase_date,
    un.is_active
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.name = 'サカイユカ3'
  AND u.user_id = 'ys0888'
ORDER BY un.created_at DESC
LIMIT 1;

SELECT '=== デバッグ完了 ===' as status;