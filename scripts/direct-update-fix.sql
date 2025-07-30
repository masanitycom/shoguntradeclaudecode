-- 直接更新による修復: 既存レコードのIDを変更

BEGIN;

-- Step 1: サトウチヨコ002のIDを新しいIDに直接変更
UPDATE users 
SET id = 'f0408d59-9290-4491-92e3-f9d11c50dd15'
WHERE id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
  AND email = 'phu55papa@gmail.com';

-- Step 2: サトウチヨコ002のNFTデータのuser_idを新IDに更新
UPDATE user_nfts 
SET user_id = 'f0408d59-9290-4491-92e3-f9d11c50dd15'
WHERE user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

-- Step 3: サトウチヨコ002の関連データも更新
UPDATE daily_rewards 
SET user_id = 'f0408d59-9290-4491-92e3-f9d11c50dd15' 
WHERE user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

UPDATE nft_purchase_applications 
SET user_id = 'f0408d59-9290-4491-92e3-f9d11c50dd15' 
WHERE user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

UPDATE reward_applications 
SET user_id = 'f0408d59-9290-4491-92e3-f9d11c50dd15' 
WHERE user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

-- Step 4: 紹介関係の更新
UPDATE users 
SET referrer_id = 'f0408d59-9290-4491-92e3-f9d11c50dd15' 
WHERE referrer_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

COMMIT;

-- 中間確認
SELECT 'Step 1 completed: Sato moved to new ID' as status;
SELECT 
    id, name, email, user_id,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = users.id) as nft_count
FROM users 
WHERE id = 'f0408d59-9290-4491-92e3-f9d11c50dd15';

-- Step 5: イシジマカツヒロのIDを正しいauth IDに変更
BEGIN;

UPDATE users 
SET id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE id = '53b6f22b-5348-4fe2-a969-b522655e8a4a'
  AND email = 'kappystone.516@gmail.com';

-- Step 6: イシジマカツヒロのNFTデータのuser_idを正しいIDに更新
UPDATE user_nfts 
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- Step 7: イシジマカツヒロの関連データも更新
UPDATE daily_rewards 
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' 
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

UPDATE nft_purchase_applications 
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' 
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

UPDATE reward_applications 
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' 
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- Step 8: 紹介関係の更新
UPDATE users 
SET referrer_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' 
WHERE referrer_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

COMMIT;

-- 最終検証
SELECT 'DIRECT UPDATE COMPLETED!' as status;

-- kappystone認証確認
SELECT 
    '=== FINAL VERIFICATION ===' as section,
    au.email,
    au.id as auth_id,
    pu.id as public_id,
    CASE WHEN au.id = pu.id THEN 'SYNCED ✓' ELSE 'ERROR ✗' END as sync_status,
    pu.name,
    pu.user_id,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = pu.id) as nft_count,
    (SELECT SUM(current_investment::numeric) FROM user_nfts WHERE user_id = pu.id) as total_investment
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE au.email = 'kappystone.516@gmail.com';

-- 両ユーザーの最終状態
SELECT 'Both users final check:' as final_check;
SELECT 
    id, name, email, user_id,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = users.id) as nft_count,
    (SELECT SUM(current_investment::numeric) FROM user_nfts WHERE user_id = users.id) as investment
FROM users 
WHERE id IN ('3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c', 'f0408d59-9290-4491-92e3-f9d11c50dd15')
ORDER BY email;