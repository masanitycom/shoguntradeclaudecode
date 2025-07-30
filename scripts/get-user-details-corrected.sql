-- 修正版: ユーザー詳細情報の取得

-- kappystone.516@gmail.com の完全な情報
SELECT 'イシジマカツヒロ の完全情報' as user_info;
SELECT 
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, 
    my_referral_code, referral_link,
    created_at, updated_at
FROM users 
WHERE email = 'kappystone.516@gmail.com';

-- サトウチヨコ002 の情報（混在の原因）
SELECT 'サトウチヨコ002 の完全情報' as user_info;
SELECT 
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin,
    my_referral_code, referral_link, 
    created_at, updated_at
FROM users 
WHERE id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

-- referrer情報も含めて取得
SELECT 'referrer関係の詳細' as referrer_info;
SELECT 
    u.id,
    u.name,
    u.email,
    u.user_id,
    u.referrer_id,
    r.name as referrer_name,
    r.user_id as referrer_user_id
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.email IN ('kappystone.516@gmail.com', 'phu55papa@gmail.com');

-- 関連するNFTの詳細情報
SELECT 'NFT関連データ' as nft_info;
SELECT 
    un.id as nft_record_id,
    un.user_id,
    u.name as owner_name,
    u.email as owner_email,
    n.name as nft_name,
    un.current_investment,
    un.total_earned,
    un.max_earning,
    un.is_active,
    un.purchase_date,
    un.operation_start_date,
    un.created_at
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id  
WHERE u.email IN ('kappystone.516@gmail.com', 'phu55papa@gmail.com')
ORDER BY un.created_at;