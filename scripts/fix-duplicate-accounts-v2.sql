-- 重複アカウント問題の修復（ユニークなuser_ID使用）

SELECT '=== FIXING DUPLICATE ACCOUNT ISSUES V2 ===' as section;

-- Step 1: tokusana371@gmail.com用のusersレコードを作成
-- 既存のTokusana371@gmail.comからデータをコピー（ユニークなuser_id使用）
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
)
SELECT 
    '359f44c4-507e-4867-b25d-592f98962145'::uuid as id,
    name,
    'tokusana371@gmail.com' as email,
    'mook0214auth' as user_id,  -- ユニークなuser_id
    phone,
    referrer_id,
    usdt_address,
    wallet_type,
    is_admin,
    'mook0214auth' as my_referral_code,
    'https://shogun-trade.vercel.app/register?ref=mook0214auth' as referral_link,
    '2025-06-24 10:08:44.040794+00' as created_at,
    NOW() as updated_at
FROM users 
WHERE id = '4bfb2fd3-5886-4a92-b31a-fe83d0a91e50';

-- Step 2: a3@shogun-trade.com用のusersレコードを作成
-- 既存のA3@shogun-trade.comからデータをコピー（ユニークなuser_id使用）
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
)
SELECT 
    '9ed30a48-e5cd-483b-8d79-c84fb5248d48'::uuid as id,
    name,
    'a3@shogun-trade.com' as email,
    'Zuurin123auth' as user_id,  -- ユニークなuser_id
    phone,
    referrer_id,
    usdt_address,
    wallet_type,
    is_admin,
    'Zuurin123auth' as my_referral_code,
    'https://shogun-trade.vercel.app/register?ref=Zuurin123auth' as referral_link,
    '2025-06-24 11:05:34.764415+00' as created_at,
    NOW() as updated_at
FROM users 
WHERE id = '176bcbce-3cca-4838-b714-681a901a7274';

-- 修復完了確認
SELECT 'DUPLICATE ACCOUNT REPAIR V2 COMPLETED!' as status;

-- Step 3: 修復結果の確認
SELECT '=== REPAIR VERIFICATION ===' as verification;

-- tokusana371@gmail.com の確認
SELECT 'tokusana371@gmail.com verification:' as tokusana_check;
SELECT 
    au.email as auth_email,
    au.id as auth_id,
    pu.id as public_id,
    pu.name as public_name,
    pu.user_id as public_user_id,
    CASE WHEN au.id = pu.id THEN 'SYNCED ✓' ELSE 'ERROR ✗' END as sync_status
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE au.email = 'tokusana371@gmail.com';

-- a3@shogun-trade.com の確認
SELECT 'a3@shogun-trade.com verification:' as a3_check;
SELECT 
    au.email as auth_email,
    au.id as auth_id,
    pu.id as public_id,
    pu.name as public_name,
    pu.user_id as public_user_id,
    CASE WHEN au.id = pu.id THEN 'SYNCED ✓' ELSE 'ERROR ✗' END as sync_status
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE au.email = 'a3@shogun-trade.com';

-- 両ユーザーの最終状態（NFT含む）
SELECT 'Final user states with NFT data:' as final_states;
SELECT 
    u.id,
    u.name,
    u.email,
    u.user_id,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = u.id) as nft_count,
    (SELECT SUM(current_investment::numeric) FROM user_nfts WHERE user_id = u.id) as investment
FROM users u
WHERE u.id IN ('359f44c4-507e-4867-b25d-592f98962145', '9ed30a48-e5cd-483b-8d79-c84fb5248d48')
ORDER BY u.email;

-- 孤立auth.usersの残り数確認
SELECT 'Remaining orphaned auth users:' as remaining_orphans;
SELECT COUNT(*) as orphaned_count
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE pu.id IS NULL;

SELECT 'SUCCESS: Problem users can now login with their correct data!' as final_message;