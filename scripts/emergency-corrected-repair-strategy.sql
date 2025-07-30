-- 修正された緊急修復戦略
-- phu55papa@gmail.com はauth.usersに存在しないため、kappystone.516@gmail.com のデータを正しく移動

SELECT '=== CORRECTED EMERGENCY REPAIR STRATEGY ===' as section;

-- 現在の状況確認
SELECT 'Current Mixed Data Situation' as info;
SELECT 
    'ID: 3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' as mixed_id,
    'Contains: kappystone.516@gmail.com (auth exists) + phu55papa@gmail.com data (no auth)' as problem,
    'Solution: Move kappystone data to separate ID, keep phu55papa data in mixed ID' as strategy;

-- Step 1: 新しいIDでkappystone.516@gmail.com用のpublic.usersレコード作成
-- まず利用可能な新しいUUIDを生成（または手動指定）
SELECT 'REPAIR PLAN:' as plan;
SELECT 
    '1. Create new public.users record for kappystone.516@gmail.com' as step1,
    '2. Move kappystone NFT data to new ID' as step2,
    '3. Update referrer relationships' as step3,
    '4. Keep phu55papa data in original mixed ID (3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c)' as step4;

-- 新しいUUID生成（実際の修復で使用）
SELECT 'Generated new UUID for kappystone.516@gmail.com:' as info;
SELECT gen_random_uuid() as new_kappystone_id;

-- データ移動の詳細確認
SELECT 'Data to be moved for kappystone.516@gmail.com:' as data_check;
SELECT 
    un.id as nft_record_id,
    un.current_investment,
    n.name as nft_name,
    un.purchase_date,
    un.operation_start_date,
    'This will be moved to new ID' as action
FROM user_nfts un
JOIN nfts n ON un.nft_id = n.id
WHERE un.user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

SELECT 'Data to remain with phu55papa@gmail.com:' as data_remain;
SELECT 
    un.id as nft_record_id,
    un.current_investment,
    n.name as nft_name,
    un.purchase_date,
    un.operation_start_date,
    'This stays with mixed ID (3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c)' as action
FROM user_nfts un
JOIN nfts n ON un.nft_id = n.id
WHERE un.user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';