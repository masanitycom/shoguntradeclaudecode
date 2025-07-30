-- シンプルなID修正: 既存のkappystoneレコードを正しいauth IDに移動

BEGIN;

-- Step 1: 既存のkappystone レコードのIDを正しいauth IDに更新
UPDATE users 
SET id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE id = '53b6f22b-5348-4fe2-a969-b522655e8a4a'
  AND email = 'kappystone.516@gmail.com';

-- Step 2: 関連するNFTデータのIDを更新
UPDATE user_nfts 
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- Step 3: 関連するその他のデータを更新
UPDATE daily_rewards
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'  
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

UPDATE nft_purchase_applications
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

UPDATE reward_applications  
SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE user_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

-- 紹介関係の更新
UPDATE users
SET referrer_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
WHERE referrer_id = '53b6f22b-5348-4fe2-a969-b522655e8a4a';

COMMIT;

-- 修復結果の検証
SELECT 'SIMPLE ID CORRECTION COMPLETED' as status;

-- 同期状況確認
SELECT 
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

-- 残った古いサトウチヨコ002データの確認
SELECT 'Remaining mixed data check:' as remaining_check;
SELECT 
    id, name, email, user_id, created_at
FROM users 
WHERE name = 'サトウチヨコ002' OR email = 'phu55papa@gmail.com';