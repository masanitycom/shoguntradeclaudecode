-- 大文字版対応ありの小文字アカウント作成（バッチ1: 最初の10ペア）

SELECT '=== CREATING LOWERCASE ACCOUNTS BATCH 1 ===' as section;

-- 1. b@shogun-trade.com (大文字版: B@shogun-trade.com - イノセミツアキ)
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
)
SELECT 
    'b6647604-8baa-4158-be6c-10ed45ac7bc5'::uuid as id,
    name, 'b@shogun-trade.com' as email, user_id || '_lowercase' as user_id,
    phone, referrer_id, usdt_address, wallet_type, is_admin,
    user_id || '_lowercase' as my_referral_code,
    'https://shogun-trade.vercel.app/register?ref=' || user_id || '_lowercase' as referral_link,
    '2025-06-24 09:44:27.440893+00' as created_at, NOW() as updated_at
FROM users WHERE id = '7b5ca448-0e26-4582-bac1-141471f981cb';

-- 2. c@shogun-trade.com (大文字版: C@shogun-trade.com - ソウマユウゴ2)
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
)
SELECT 
    'd898dae2-57b6-48d2-ae12-27a0fa9d7c52'::uuid as id,
    name, 'c@shogun-trade.com' as email, user_id || '_lowercase' as user_id,
    phone, referrer_id, usdt_address, wallet_type, is_admin,
    user_id || '_lowercase' as my_referral_code,
    'https://shogun-trade.vercel.app/register?ref=' || user_id || '_lowercase' as referral_link,
    '2025-06-24 09:44:28.356863+00' as created_at, NOW() as updated_at
FROM users WHERE id = '800bc8ba-a073-4050-8f1e-a76d38de5f74';

-- 3. d@shogun-trade.com (大文字版: D@shogun-trade.com - ソメヤトモコ)
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
)
SELECT 
    'fdbbfcd5-80a8-4c59-b9bf-68684d56bd03'::uuid as id,
    name, 'd@shogun-trade.com' as email, user_id || '_lowercase' as user_id,
    phone, referrer_id, usdt_address, wallet_type, is_admin,
    user_id || '_lowercase' as my_referral_code,
    'https://shogun-trade.vercel.app/register?ref=' || user_id || '_lowercase' as referral_link,
    '2025-06-24 09:44:30.674754+00' as created_at, NOW() as updated_at
FROM users WHERE id = '23447bfd-fad3-463d-bd34-0289b842cd4a';

-- 4. e@shogun-trade.com (大文字版: E@shogun-trade.com - サカイユカ2)
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
)
SELECT 
    '90ee9886-1149-4fd9-bd7c-7f3b611be5b1'::uuid as id,
    name, 'e@shogun-trade.com' as email, user_id || '_lowercase' as user_id,
    phone, referrer_id, usdt_address, wallet_type, is_admin,
    user_id || '_lowercase' as my_referral_code,
    'https://shogun-trade.vercel.app/register?ref=' || user_id || '_lowercase' as referral_link,
    '2025-06-24 09:44:33.397973+00' as created_at, NOW() as updated_at
FROM users WHERE id = 'c9aaeb8f-7a92-445c-8529-0a13c50240a0';

-- 5. f@shogun-trade.com (大文字版: F@shogun-trade.com - サカイユカ3)
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
)
SELECT 
    'bc5acf81-0d47-4485-b456-3143ff493b24'::uuid as id,
    name, 'f@shogun-trade.com' as email, user_id || '_lowercase' as user_id,
    phone, referrer_id, usdt_address, wallet_type, is_admin,
    user_id || '_lowercase' as my_referral_code,
    'https://shogun-trade.vercel.app/register?ref=' || user_id || '_lowercase' as referral_link,
    '2025-06-24 09:44:34.298743+00' as created_at, NOW() as updated_at
FROM users WHERE id = '0c15fe33-7ee3-4660-9bd5-0959d32f13d7';

SELECT 'BATCH 1 COMPLETED - 5 lowercase accounts created!' as batch1_status;