-- 既存データの詳細確認

SELECT '=== EXISTING DATA ANALYSIS ===' as section;

-- ID 3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c の現在のデータ
SELECT 'Current data in target ID:' as target_data;
SELECT 
    id, name, email, user_id, phone, referrer_id,
    created_at, updated_at,
    'TARGET ID DATA' as data_type
FROM users 
WHERE id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

-- ID 53b6f22b-5348-4fe2-a969-b522655e8a4a の現在のデータ
SELECT 'Current data in source ID:' as source_data;
SELECT 
    id, name, email, user_id, phone, referrer_id,
    created_at, updated_at,
    'SOURCE ID DATA' as data_type
FROM users 
WHERE id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- 両方のIDのNFTデータ確認
SELECT 'NFT data comparison:' as nft_comparison;
SELECT 
    un.user_id,
    u.name as owner_name,
    u.email as owner_email,
    n.name as nft_name,
    un.current_investment,
    un.is_active,
    un.created_at
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.user_id IN ('3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c', '53b6f22b-5348-4fe2-a969-b522655e8a4a')
ORDER BY un.created_at;

-- 統合戦略の提示
SELECT 'INTEGRATION STRATEGY:' as strategy;
SELECT 
    'Option 1: Delete target ID record and move source data' as option1,
    'Option 2: Merge data into target ID and delete source' as option2,
    'Option 3: Keep both records separate (not recommended)' as option3;

-- どちらがkappystone.516@gmail.comの正しいデータか確認
SELECT 'Correct kappystone data identification:' as identification;
SELECT 
    id,
    name,
    email,
    user_id,
    CASE 
        WHEN email = 'kappystone.516@gmail.com' THEN 'KAPPYSTONE DATA'
        WHEN name LIKE '%サトウ%' OR name LIKE '%チヨコ%' THEN 'SATO DATA'
        ELSE 'UNKNOWN'
    END as data_owner,
    created_at
FROM users 
WHERE id IN ('3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c', '53b6f22b-5348-4fe2-a969-b522655e8a4a')
ORDER BY created_at;