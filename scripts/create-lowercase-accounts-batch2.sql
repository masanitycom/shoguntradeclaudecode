-- 大文字版対応ありの小文字アカウント作成（バッチ2: 次の8ペア）

SELECT '=== CREATING LOWERCASE ACCOUNTS BATCH 2 ===' as section;

-- 6. g@shogun-trade.com (大文字版: G@shogun-trade.com - コジマアツコ2)
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
)
SELECT 
    'ac6640ee-fdc0-42ab-8b6e-901cc02ef3ff'::uuid as id,
    name, 'g@shogun-trade.com' as email, user_id || '_lc' as user_id,
    phone, referrer_id, usdt_address, wallet_type, is_admin,
    user_id || '_lc' as my_referral_code,
    'https://shogun-trade.vercel.app/register?ref=' || user_id || '_lc' as referral_link,
    '2025-06-24 09:44:35.199292+00' as created_at, NOW() as updated_at
FROM users WHERE id = 'd860ee09-a573-4f46-9754-275c3505dbb8';

-- 7. h@shogun-trade.com (大文字版: H@shogun-trade.com - コジマアツコ3)
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
)
SELECT 
    '1e18b500-5f7b-4a0d-9359-5a4cdc3c8e9c'::uuid as id,
    name, 'h@shogun-trade.com' as email, user_id || '_lc' as user_id,
    phone, referrer_id, usdt_address, wallet_type, is_admin,
    user_id || '_lc' as my_referral_code,
    'https://shogun-trade.vercel.app/register?ref=' || user_id || '_lc' as referral_link,
    '2025-06-24 09:44:36.099255+00' as created_at, NOW() as updated_at
FROM users WHERE id = 'a74aebad-fff2-48f7-937d-900c9a3c871b';

-- 8. i@shogun-trade.com (大文字版: I@shogun-trade.com - アイタノリコ２)
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
)
SELECT 
    '6b280a65-608e-45a1-98b5-18c4811a05a1'::uuid as id,
    name, 'i@shogun-trade.com' as email, user_id || '_lc' as user_id,
    phone, referrer_id, usdt_address, wallet_type, is_admin,
    user_id || '_lc' as my_referral_code,
    'https://shogun-trade.vercel.app/register?ref=' || user_id || '_lc' as referral_link,
    '2025-06-24 10:08:03.649551+00' as created_at, NOW() as updated_at
FROM users WHERE id = '6df11e9e-4791-4a5c-97ae-29f090e07b17';

-- 9. j@shogun-trade.com (大文字版: J@shogun-trade.com - ゴトウアヤ)
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
)
SELECT 
    'e7ed5406-f960-4277-9bd8-f6449db66f1b'::uuid as id,
    name, 'j@shogun-trade.com' as email, user_id || '_lc' as user_id,
    phone, referrer_id, usdt_address, wallet_type, is_admin,
    user_id || '_lc' as my_referral_code,
    'https://shogun-trade.vercel.app/register?ref=' || user_id || '_lc' as referral_link,
    '2025-06-24 10:08:05.594392+00' as created_at, NOW() as updated_at
FROM users WHERE id = 'd09bc7cf-8a08-45bf-8451-5ccdb046028c';

-- 10. k@shogun-trade.com (大文字版: K@shogun-trade.com - ワタヌキイチロウ)
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
)
SELECT 
    '3bf2cbcb-70e5-46bd-b7d5-07de361519f0'::uuid as id,
    name, 'k@shogun-trade.com' as email, user_id || '_lc' as user_id,
    phone, referrer_id, usdt_address, wallet_type, is_admin,
    user_id || '_lc' as my_referral_code,
    'https://shogun-trade.vercel.app/register?ref=' || user_id || '_lc' as referral_link,
    '2025-06-24 11:04:54.765742+00' as created_at, NOW() as updated_at
FROM users WHERE id = 'f608668d-5b8c-4822-9bf4-48a677c88a1b';

-- 11. m@shogun-trade.com (大文字版: M@shogun-trade.com - イノセアキコ)
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
)
SELECT 
    '89d7358b-a50d-4f2f-a79c-0b9c31fe51d4'::uuid as id,
    name, 'm@shogun-trade.com' as email, user_id || '_lc' as user_id,
    phone, referrer_id, usdt_address, wallet_type, is_admin,
    user_id || '_lc' as my_referral_code,
    'https://shogun-trade.vercel.app/register?ref=' || user_id || '_lc' as referral_link,
    '2025-06-24 11:04:57.538313+00' as created_at, NOW() as updated_at
FROM users WHERE id = '1b42e0d1-118f-49e1-b648-da65304eec29';

-- 12. n@shogun-trade.com (大文字版: N@shogun-trade.com - シマダフミコ2)
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
)
SELECT 
    '9c55954a-510d-44ec-b8e0-8482514e8fa2'::uuid as id,
    name, 'n@shogun-trade.com' as email, user_id || '_lc' as user_id,
    phone, referrer_id, usdt_address, wallet_type, is_admin,
    user_id || '_lc' as my_referral_code,
    'https://shogun-trade.vercel.app/register?ref=' || user_id || '_lc' as referral_link,
    '2025-06-24 11:04:59.538101+00' as created_at, NOW() as updated_at
FROM users WHERE id = '16008c8d-5d70-4006-807f-018c810a7cc4';

-- 13. o@shogun-trade.com (大文字版: O@shogun-trade.com - ノグチチヨコ2)
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
)
SELECT 
    '37026109-bd49-4a75-bce4-4826e0d300f1'::uuid as id,
    name, 'o@shogun-trade.com' as email, user_id || '_lc' as user_id,
    phone, referrer_id, usdt_address, wallet_type, is_admin,
    user_id || '_lc' as my_referral_code,
    'https://shogun-trade.vercel.app/register?ref=' || user_id || '_lc' as referral_link,
    '2025-06-24 10:08:21.417388+00' as created_at, NOW() as updated_at
FROM users WHERE id = '56f9ad59-a7f8-40ac-94d9-e28e7ef9cdb3';

SELECT 'BATCH 2 COMPLETED - 8 more lowercase accounts created!' as batch2_status;

-- 確認クエリ
SELECT 'Batch 2 verification:' as verification;
SELECT id, name, email, user_id FROM users 
WHERE id IN (
    'ac6640ee-fdc0-42ab-8b6e-901cc02ef3ff',
    '1e18b500-5f7b-4a0d-9359-5a4cdc3c8e9c',
    '6b280a65-608e-45a1-98b5-18c4811a05a1',
    'e7ed5406-f960-4277-9bd8-f6449db66f1b',
    '3bf2cbcb-70e5-46bd-b7d5-07de361519f0',
    '89d7358b-a50d-4f2f-a79c-0b9c31fe51d4',
    '9c55954a-510d-44ec-b8e0-8482514e8fa2',
    '37026109-bd49-4a75-bce4-4826e0d300f1'
);

SELECT 'SUCCESS: Batch 2 accounts ready for NFT migration!' as success_message;