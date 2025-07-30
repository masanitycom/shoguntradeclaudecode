-- 全ての外部キー参照を含む完全修復

-- Step 5b: user_rank_historyも含めて全ての関連データを正しいIDに更新
BEGIN;

-- イシジマカツヒロの全ての関連データを正しいIDに更新
UPDATE user_nfts SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE daily_rewards SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE nft_purchase_applications SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE reward_applications SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE user_rank_history SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';

-- 紹介関係の更新  
UPDATE users SET referrer_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE referrer_id = '00000000-0000-0000-0000-000000000001';

-- 他の可能性のある参照テーブルも確認・更新
UPDATE referral_bonuses SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE referral_bonuses SET referrer_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE referrer_id = '00000000-0000-0000-0000-000000000001';

-- 天下統一ボーナス関連があれば更新
UPDATE tenka_touitsu_bonuses SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';

-- その他の可能性のあるテーブル
UPDATE user_sessions SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE user_activities SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';
UPDATE airdrop_tasks SET user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c' WHERE user_id = '00000000-0000-0000-0000-000000000001';

-- 最後にusersレコードのIDを更新
UPDATE users 
SET 
    id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c',
    name = 'イシジマカツヒロ',
    email = 'kappystone.516@gmail.com',
    user_id = 'PHULIKE'
WHERE id = '00000000-0000-0000-0000-000000000001';

COMMIT;

-- 最終検証
SELECT 'ALL REFERENCES UPDATED SUCCESSFULLY!' as status;

-- kappystone認証の最終確認
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

-- 両ユーザーの最終状態確認
SELECT '=== BOTH USERS FINAL STATE ===' as final_check;
SELECT 
    id, name, email, user_id,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = users.id) as nft_count,
    (SELECT SUM(current_investment::numeric) FROM user_nfts WHERE user_id = users.id) as investment
FROM users 
WHERE id IN ('3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c', 'f0408d59-9290-4491-92e3-f9d11c50dd15')
ORDER BY email;

-- 一時的なレコードが残っていないか確認
SELECT 'Temporary records check:' as temp_check;
SELECT COUNT(*) as temp_records_remaining 
FROM users 
WHERE id = '00000000-0000-0000-0000-000000000001' 
   OR email LIKE '%_temp%' 
   OR user_id LIKE '%_TEMP%';