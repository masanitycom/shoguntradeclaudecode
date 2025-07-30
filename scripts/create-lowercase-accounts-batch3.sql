-- 大文字版対応ありの小文字アカウント作成（バッチ3: 最後の8ペア）

SELECT '=== CREATING LOWERCASE ACCOUNTS BATCH 3 (FINAL) ===' as section;

-- 14. p@shogun-trade.com (大文字版: P@shogun-trade.com - カタオカマキ)
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
)
SELECT 
    '5bff5144-c714-4c94-89da-0413e5b2edee'::uuid as id,
    name, 'p@shogun-trade.com' as email, user_id || '_lc' as user_id,
    phone, referrer_id, usdt_address, wallet_type, is_admin,
    user_id || '_lc' as my_referral_code,
    'https://shogun-trade.vercel.app/register?ref=' || user_id || '_lc' as referral_link,
    '2025-06-24 10:08:38.026724+00' as created_at, NOW() as updated_at
FROM users WHERE id = 'b1865f42-b846-4d07-9f59-f4a6bb1dbb42';

-- 15. q@shogun-trade.com (大文字版: Q@shogun-trade.com - シマダフミコ3)
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
)
SELECT 
    'e6b81dac-915a-489d-8213-eb23c4f0f76d'::uuid as id,
    name, 'q@shogun-trade.com' as email, user_id || '_lc' as user_id,
    phone, referrer_id, usdt_address, wallet_type, is_admin,
    user_id || '_lc' as my_referral_code,
    'https://shogun-trade.vercel.app/register?ref=' || user_id || '_lc' as referral_link,
    '2025-06-24 10:08:39.218043+00' as created_at, NOW() as updated_at
FROM users WHERE id = '6af12598-cff0-4cea-9d0e-9396518fbc10';

-- 16. r@shogun-trade.com (大文字版: R@shogun-trade.com - シマダフミコ4)
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
)
SELECT 
    '04183cb9-386e-4aa6-bda7-97d21cbfc287'::uuid as id,
    name, 'r@shogun-trade.com' as email, user_id || '_lc' as user_id,
    phone, referrer_id, usdt_address, wallet_type, is_admin,
    user_id || '_lc' as my_referral_code,
    'https://shogun-trade.vercel.app/register?ref=' || user_id || '_lc' as referral_link,
    '2025-06-24 10:08:40.034492+00' as created_at, NOW() as updated_at
FROM users WHERE id = '347364df-69c0-4f80-b07e-6ed1c469fd5c';

-- 17. u@shogun-trade.com (大文字版: U@shogun-trade.com - コジマアツコ4)
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
)
SELECT 
    'c8e1b8f7-c687-4765-9856-3fe07c083b67'::uuid as id,
    name, 'u@shogun-trade.com' as email, user_id || '_lc' as user_id,
    phone, referrer_id, usdt_address, wallet_type, is_admin,
    user_id || '_lc' as my_referral_code,
    'https://shogun-trade.vercel.app/register?ref=' || user_id || '_lc' as referral_link,
    '2025-06-24 11:05:06.903231+00' as created_at, NOW() as updated_at
FROM users WHERE id = 'f40d7304-6602-4f1a-b328-4a57bb913a1c';

-- 18. v@shogun-trade.com (大文字版: V@shogun-trade.com - ヤナギダカツミ2)
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
)
SELECT 
    'd460ff12-87ce-4474-8dcf-6040565951ec'::uuid as id,
    name, 'v@shogun-trade.com' as email, user_id || '_lc' as user_id,
    phone, referrer_id, usdt_address, wallet_type, is_admin,
    user_id || '_lc' as my_referral_code,
    'https://shogun-trade.vercel.app/register?ref=' || user_id || '_lc' as referral_link,
    '2025-06-24 11:05:07.578551+00' as created_at, NOW() as updated_at
FROM users WHERE id = '5c3bf22c-791e-49ff-837d-708ef3cf5a6f';

-- 19. w@shogun-trade.com (大文字版: W@shogun-trade.com - ヤタガワタクミ)
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
)
SELECT 
    '0ebf4469-a96a-4f1e-a16c-f3613f8beb22'::uuid as id,
    name, 'w@shogun-trade.com' as email, user_id || '_lc' as user_id,
    phone, referrer_id, usdt_address, wallet_type, is_admin,
    user_id || '_lc' as my_referral_code,
    'https://shogun-trade.vercel.app/register?ref=' || user_id || '_lc' as referral_link,
    '2025-06-24 10:09:00.37848+00' as created_at, NOW() as updated_at
FROM users WHERE id = 'f2a6a70b-1067-4ff8-9451-bec65717ed5b';

-- 20. y@shogun-trade.com (大文字版: Y@shogun-trade.com - オジマケンイチ)
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
)
SELECT 
    '1a252fa3-54ee-4983-a476-75bb90f78e2b'::uuid as id,
    name, 'y@shogun-trade.com' as email, user_id || '_lc' as user_id,
    phone, referrer_id, usdt_address, wallet_type, is_admin,
    user_id || '_lc' as my_referral_code,
    'https://shogun-trade.vercel.app/register?ref=' || user_id || '_lc' as referral_link,
    '2025-06-24 11:05:21.463172+00' as created_at, NOW() as updated_at
FROM users WHERE id = '3dc28c08-3ff3-4932-b340-cbf4036572fd';

-- 21. z@shogun-trade.com (大文字版: Z@shogun-trade.com - オジマタカオ)
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
)
SELECT 
    '3c142554-2169-441a-a78f-bdf034ad417f'::uuid as id,
    name, 'z@shogun-trade.com' as email, user_id || '_lc' as user_id,
    phone, referrer_id, usdt_address, wallet_type, is_admin,
    user_id || '_lc' as my_referral_code,
    'https://shogun-trade.vercel.app/register?ref=' || user_id || '_lc' as referral_link,
    '2025-06-24 11:05:22.122445+00' as created_at, NOW() as updated_at
FROM users WHERE id = 'f541e550-9b2d-4dc3-80ce-0f7500b7ab80';

SELECT 'BATCH 3 FINAL COMPLETED - All 21 pairs of lowercase accounts created!' as batch3_status;

-- 確認クエリ
SELECT 'Batch 3 verification:' as verification;
SELECT id, name, email, user_id FROM users 
WHERE id IN (
    '5bff5144-c714-4c94-89da-0413e5b2edee',
    'e6b81dac-915a-489d-8213-eb23c4f0f76d',
    '04183cb9-386e-4aa6-bda7-97d21cbfc287',
    'c8e1b8f7-c687-4765-9856-3fe07c083b67',
    'd460ff12-87ce-4474-8dcf-6040565951ec',
    '0ebf4469-a96a-4f1e-a16c-f3613f8beb22',
    '1a252fa3-54ee-4983-a476-75bb90f78e2b',
    '3c142554-2169-441a-a78f-bdf034ad417f'
);

SELECT 'SUCCESS: All 21 pairs of uppercase/lowercase accounts are now ready!' as success_message;