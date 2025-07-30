-- NFT制限エラーの詳細調査
SELECT '=== NFT CONFLICT INVESTIGATION ===' as section;

-- 3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c のNFT保有状況
SELECT 'Target User NFT Holdings' as info;
SELECT 
    un.id as nft_record_id,
    un.user_id,
    u.name as owner_name,
    u.email as owner_email,
    n.name as nft_name,
    un.current_investment,
    un.is_active,
    un.purchase_date,
    un.operation_start_date,
    un.created_at
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id  
WHERE un.user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
ORDER BY un.created_at;

-- 移動元のNFT詳細
SELECT 'Source User NFT Holdings' as info;
SELECT 
    un.id as nft_record_id,
    un.user_id,
    u.name as owner_name,
    u.email as owner_email,
    n.name as nft_name,
    un.current_investment,
    un.is_active,
    un.purchase_date,
    un.operation_start_date,
    un.created_at
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id  
WHERE un.user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a'
ORDER BY un.created_at;

-- 両方のユーザーの詳細情報
SELECT 'User Details Comparison' as info;
SELECT 
    id, name, email, user_id, created_at,
    CASE 
        WHEN id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' THEN 'TARGET (auth ID)'
        WHEN id = '53b6f22b-5348-4fe2-a969-b522655e8a4a' THEN 'SOURCE (wrong ID)'
        ELSE 'OTHER'
    END as user_type
FROM users 
WHERE id IN ('3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c', '53b6f22b-5348-4fe2-a969-b522655e8a4a')
ORDER BY created_at;

-- auth.users での確認
SELECT 'Auth Users Verification' as info;
SELECT 
    id, email, created_at,
    CASE 
        WHEN id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' THEN 'CORRECT AUTH ID'
        ELSE 'OTHER'
    END as auth_status
FROM auth.users 
WHERE email = 'kappystone.516@gmail.com' OR id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';