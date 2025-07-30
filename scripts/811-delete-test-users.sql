-- テストユーザーの削除

SELECT '=== DELETING TEST USERS ===' as section;

-- 削除対象ユーザーの確認
SELECT 'Test users to be deleted:' as info;
SELECT COUNT(*) as count_to_delete
FROM users
WHERE email LIKE '%@shogun-trade.com%' 
   OR email LIKE '%@shogun-trade.co%'
   OR name LIKE 'ユーザー%UP'
   OR name LIKE 'ユーザー%'
   OR phone = '000-0000-0000';

-- 1. まずuser_nftsから削除（外部キー制約のため）
SELECT 'Deleting user_nfts for test users...' as action;
DELETE FROM user_nfts
WHERE user_id IN (
    SELECT id FROM users
    WHERE email LIKE '%@shogun-trade.com%' 
       OR email LIKE '%@shogun-trade.co%'
       OR name LIKE 'ユーザー%UP'
       OR name LIKE 'ユーザー%'
       OR phone = '000-0000-0000'
);

-- 2. daily_rewardsから削除
SELECT 'Deleting daily_rewards for test users...' as action;
DELETE FROM daily_rewards
WHERE user_id IN (
    SELECT id FROM users
    WHERE email LIKE '%@shogun-trade.com%' 
       OR email LIKE '%@shogun-trade.co%'
       OR name LIKE 'ユーザー%UP'
       OR name LIKE 'ユーザー%'
       OR phone = '000-0000-0000'
);

-- 3. mlm_downline_volumesから削除
SELECT 'Deleting mlm_downline_volumes for test users...' as action;
DELETE FROM mlm_downline_volumes
WHERE user_id IN (
    SELECT id FROM users
    WHERE email LIKE '%@shogun-trade.com%' 
       OR email LIKE '%@shogun-trade.co%'
       OR name LIKE 'ユーザー%UP'
       OR name LIKE 'ユーザー%'
       OR phone = '000-0000-0000'
);

-- 4. reward_claimsから削除
SELECT 'Deleting reward_claims for test users...' as action;
DELETE FROM reward_claims
WHERE user_id IN (
    SELECT id FROM users
    WHERE email LIKE '%@shogun-trade.com%' 
       OR email LIKE '%@shogun-trade.co%'
       OR name LIKE 'ユーザー%UP'
       OR name LIKE 'ユーザー%'
       OR phone = '000-0000-0000'
);

-- 5. 最後にusersテーブルから削除（ただしadminは除外）
SELECT 'Deleting test users from users table...' as action;
DELETE FROM users
WHERE (email LIKE '%@shogun-trade.com%' 
   OR email LIKE '%@shogun-trade.co%'
   OR name LIKE 'ユーザー%UP'
   OR name LIKE 'ユーザー%'
   OR phone = '000-0000-0000')
   AND email != 'admin@shogun-trade.com';

-- 6. 削除結果確認
SELECT 'Deletion complete. Remaining users:' as result;
SELECT COUNT(*) as remaining_users FROM users;

SELECT 'Users with @shogun-trade domain after deletion:' as check;
SELECT COUNT(*) as remaining_test_users
FROM users
WHERE email LIKE '%@shogun-trade.com%' 
   OR email LIKE '%@shogun-trade.co%';

SELECT '=== TEST USER CLEANUP COMPLETE ===' as status;