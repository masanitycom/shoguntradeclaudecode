-- メール重複の確認

SELECT '=== EMAIL DUPLICATE CHECK ===' as section;

-- phu55papa@gmail.com を持つ全レコード
SELECT 'All phu55papa@gmail.com records:' as info;
SELECT 
    id, name, email, user_id, created_at, updated_at
FROM users 
WHERE email = 'phu55papa@gmail.com'
ORDER BY created_at;

-- kappystone.516@gmail.com を持つ全レコード  
SELECT 'All kappystone.516@gmail.com records:' as info;
SELECT 
    id, name, email, user_id, created_at, updated_at
FROM users 
WHERE email = 'kappystone.516@gmail.com'
ORDER BY created_at;

-- 新しいIDが既に存在するか確認
SELECT 'Check if new ID already exists:' as check_new_id;
SELECT 
    id, name, email, user_id, created_at
FROM users 
WHERE id = 'f0408d59-9290-4491-92e3-f9d11c50dd15';

-- 現在のNFT所有状況
SELECT 'Current NFT ownership:' as nft_status;
SELECT 
    un.user_id,
    u.name as owner_name,
    u.email as owner_email,
    n.name as nft_name,
    un.current_investment,
    un.is_active
FROM user_nfts un
LEFT JOIN users u ON un.user_id = u.id
LEFT JOIN nfts n ON un.nft_id = n.id
WHERE u.email IN ('kappystone.516@gmail.com', 'phu55papa@gmail.com')
   OR un.user_id IN ('3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c', '53b6f22b-5348-4fe2-a969-b522655e8a4a', 'f0408d59-9290-4491-92e3-f9d11c50dd15')
ORDER BY un.created_at;