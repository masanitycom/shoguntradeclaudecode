-- phu55papa@gmail.com の処理
-- auth.usersに存在しないため、新しいauth アカウント作成が必要

SELECT '=== PHU55PAPA DATA ANALYSIS ===' as section;

-- 現在のphu55papa データ確認  
SELECT 'Current phu55papa data (mixed in kappystone auth ID):' as info;
SELECT 
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, created_at
FROM users 
WHERE id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
  AND name = 'サトウチヨコ002';

-- phu55papa のNFTデータ
SELECT 'phu55papa NFT holdings:' as nft_info;
SELECT 
    un.id as nft_record_id,
    un.current_investment,
    n.name as nft_name,
    un.purchase_date,
    un.operation_start_date,
    un.is_active
FROM user_nfts un
JOIN nfts n ON un.nft_id = n.id
WHERE un.user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
  AND EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = un.user_id 
    AND u.name = 'サトウチヨコ002'
  );

-- 解決策の提示
SELECT 'RESOLUTION OPTIONS FOR PHU55PAPA:' as options;
SELECT 
    'Option 1: Create new auth.users account for phu55papa@gmail.com' as option1,
    'Option 2: Keep data but user cannot login (orphaned investment)' as option2,
    'Option 3: Contact user to create new account and transfer data' as option3;

-- 推奨アクション
SELECT 'RECOMMENDED ACTION:' as recommendation;
SELECT 
    'Keep phu55papa data in public.users table' as action1,
    'User cannot login until new auth account created' as action2,
    'Investment data ($100) is preserved' as action3,
    'Admin can manually create auth account later if needed' as action4;