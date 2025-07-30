-- 現在のデータ状況の詳細確認

SELECT '=== CURRENT DATABASE STATE DEBUG ===' as section;

-- 全てのNYANKOユーザー確認
SELECT 'All NYANKO users:' as nyanko_users;
SELECT 
    id, name, email, user_id, created_at, updated_at
FROM users 
WHERE user_id = 'NYANKO'
ORDER BY created_at;

-- 全てのPHULIKEユーザー確認  
SELECT 'All PHULIKE users:' as phulike_users;
SELECT 
    id, name, email, user_id, created_at, updated_at
FROM users 
WHERE user_id = 'PHULIKE'
ORDER BY created_at;

-- 特定のIDのユーザー確認
SELECT 'Specific ID users:' as specific_ids;
SELECT 
    id, name, email, user_id, created_at, updated_at,
    CASE 
        WHEN id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' THEN 'TARGET_ID'
        WHEN id = '53b6f22b-5348-4fe2-a969-b522655e8a4a' THEN 'SOURCE_ID'
        WHEN id = 'f0408d59-9290-4491-92e3-f9d11c50dd15' THEN 'NEW_ID'
        ELSE 'OTHER'
    END as id_type
FROM users 
WHERE id IN (
    '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c',
    '53b6f22b-5348-4fe2-a969-b522655e8a4a', 
    'f0408d59-9290-4491-92e3-f9d11c50dd15'
)
ORDER BY created_at;

-- NFTデータの現在の状況
SELECT 'Current NFT ownership:' as nft_ownership;
SELECT 
    un.user_id,
    u.name as owner_name,
    u.email as owner_email,
    u.user_id as display_user_id,
    n.name as nft_name,
    un.current_investment,
    un.is_active
FROM user_nfts un
LEFT JOIN users u ON un.user_id = u.id
LEFT JOIN nfts n ON un.nft_id = n.id
WHERE un.user_id IN (
    '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c',
    '53b6f22b-5348-4fe2-a969-b522655e8a4a',
    'f0408d59-9290-4491-92e3-f9d11c50dd15'
) OR u.email IN ('kappystone.516@gmail.com', 'phu55papa@gmail.com')
ORDER BY un.created_at;

-- 実行すべき修復計画
SELECT 'RECOMMENDED REPAIR PLAN:' as plan;
SELECT 
    'Step 1: Clean up any partial migration data' as step1,
    'Step 2: Identify which records actually exist' as step2,
    'Step 3: Execute single-step correction' as step3,
    'Step 4: Verify auth sync' as step4;