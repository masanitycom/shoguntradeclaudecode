-- ダッシュボードで使用されているクエリをデバッグ

-- 1. 実際のダッシュボードクエリをテスト（イワネナオヤの例）
SELECT 
    'ダッシュボードクエリテスト' as check_type,
    un.id,
    un.nft_id,
    un.current_investment,
    un.total_earned,
    un.max_earning,
    un.is_active,
    n.name,
    n.image_url,
    n.daily_rate_limit,
    n.price
FROM user_nfts un
JOIN nfts n ON n.id = un.nft_id
JOIN users u ON u.id = un.user_id
WHERE u.email = 'iwanedenki@gmail.com'
AND un.is_active = true;

-- 2. 結合に問題がないか確認
SELECT 
    '結合確認' as check_type,
    COUNT(*) as total_user_nfts,
    COUNT(n.id) as joined_nfts,
    COUNT(CASE WHEN n.price IS NULL THEN 1 END) as null_prices
FROM user_nfts un
LEFT JOIN nfts n ON n.id = un.nft_id
WHERE un.is_active = true;

-- 3. NFTの価格データ確認
SELECT 
    'NFT価格データ' as check_type,
    n.id,
    n.name,
    n.price,
    n.daily_rate_limit,
    COUNT(un.id) as user_count
FROM nfts n
LEFT JOIN user_nfts un ON un.nft_id = n.id AND un.is_active = true
GROUP BY n.id, n.name, n.price, n.daily_rate_limit
ORDER BY n.price DESC;

-- 4. 特定ユーザーの詳細確認
SELECT 
    'イワネナオヤ詳細' as check_type,
    u.name,
    u.email,
    un.current_investment,
    un.total_earned,
    n.name as nft_name,
    n.price as nft_price,
    n.daily_rate_limit
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON n.id = un.nft_id
WHERE u.email = 'iwanedenki@gmail.com'
AND un.is_active = true;
