-- 混在データの修復戦略
-- 1つのauth IDに2ユーザーのデータが混在している問題の解決

SELECT '=== MIXED DATA REPAIR STRATEGY ===' as section;

-- Step 1: サトウチヨコ002用の新しいIDを生成して分離
-- まず、phu55papa@gmail.com のauth.users IDを確認
SELECT 'Auth ID for phu55papa@gmail.com' as info;
SELECT id, email, created_at 
FROM auth.users 
WHERE email = 'phu55papa@gmail.com';

-- Step 2: 現在の混在状況の詳細確認
SELECT 'Current Mixed Data Situation' as info;
SELECT 
    'Mixed ID: 3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' as problem,
    'Contains data for both users' as issue,
    'Need to separate them safely' as solution;

-- Step 3: 各ユーザーのNFT詳細を再確認
SELECT 'NFT Ownership Details' as info;
SELECT 
    un.user_id,
    u.name as current_name,
    u.email as current_email,
    n.name as nft_name,
    un.current_investment,
    un.created_at,
    CASE 
        WHEN u.email = 'kappystone.516@gmail.com' THEN 'BELONGS TO ISHIJIMA'
        WHEN u.email = 'phu55papa@gmail.com' THEN 'BELONGS TO SATO'
        ELSE 'UNKNOWN'
    END as correct_owner
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.user_id IN ('3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c', '53b6f22b-5348-4fe2-a969-b522655e8a4a')
ORDER BY un.created_at;

-- Step 4: 修復計画の提示
SELECT 'REPAIR PLAN' as info;
SELECT 
    '1. Find correct auth ID for phu55papa@gmail.com' as step1,
    '2. Move Sato data to correct auth ID' as step2,
    '3. Update Ishijima data to use correct auth ID' as step3,
    '4. Verify separation is complete' as step4;