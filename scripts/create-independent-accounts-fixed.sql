-- 25個の完全独立アカウントの新規usersレコード作成（修正版）

SELECT '=== CREATING INDEPENDENT ACCOUNTS (25 accounts) FIXED ===' as section;

-- 1. a1@shogun-trade.com
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    '8e1edcf1-eded-40a1-8c11-a3adb771fd4b',
    'ユーザーA1', 'a1@shogun-trade.com', 'a1user',
    '000-0000-0000', NULL, NULL, 'その他', false, 'a1user',
    'https://shogun-trade.vercel.app/register?ref=a1user',
    '2025-06-24 11:05:28.826098+00', NOW()
);

-- 2. A1@shogun-trade.com
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    '823d7463-6990-4a82-bc7a-d950bc3e3bb7',
    'ユーザーA1UP', 'A1@shogun-trade.com', 'A1user',
    '000-0000-0000', NULL, NULL, 'その他', false, 'A1user',
    'https://shogun-trade.vercel.app/register?ref=A1user',
    '2025-06-26 04:20:09.784831+00', NOW()
);

-- 3. a10@shogun-trade.com
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    '85ba8cc8-ba0d-4e46-9077-bc024897ba3f',
    'ユーザーA10', 'a10@shogun-trade.com', 'a10user',
    '000-0000-0000', NULL, NULL, 'その他', false, 'a10user',
    'https://shogun-trade.vercel.app/register?ref=a10user',
    '2025-06-24 11:05:47.473433+00', NOW()
);

-- 4. a2@shogun-trade.com
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    '7ced2f89-3d8a-4b21-aab6-a5e7d4393c73',
    'ユーザーA2', 'a2@shogun-trade.com', 'a2user',
    '000-0000-0000', NULL, NULL, 'その他', false, 'a2user',
    'https://shogun-trade.vercel.app/register?ref=a2user',
    '2025-06-24 11:05:30.809084+00', NOW()
);

-- 5. A2@shogun-trade.com
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    'b161fbed-037f-4a47-a223-d8752e8c8c9d',
    'ユーザーA2UP', 'A2@shogun-trade.com', 'A2user',
    '000-0000-0000', NULL, NULL, 'その他', false, 'A2user',
    'https://shogun-trade.vercel.app/register?ref=A2user',
    '2025-06-26 04:20:09.784831+00', NOW()
);

-- 6. a4@shogun-trade.com
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    '3b4f4059-b138-4e49-9be2-93481e1b2b74',
    'ユーザーA4', 'a4@shogun-trade.com', 'a4user',
    '000-0000-0000', NULL, NULL, 'その他', false, 'a4user',
    'https://shogun-trade.vercel.app/register?ref=a4user',
    '2025-06-24 11:05:38.079808+00', NOW()
);

-- 7. A4@shogun-trade.com
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    '9a495c71-00e0-4bb8-b65d-8eb98c578344',
    'ユーザーA4UP', 'A4@shogun-trade.com', 'A4user',
    '000-0000-0000', NULL, NULL, 'その他', false, 'A4user',
    'https://shogun-trade.vercel.app/register?ref=A4user',
    '2025-06-26 04:20:09.784831+00', NOW()
);

-- 8. a5@shogun-trade.co
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    '8815010c-6be0-48df-a255-8fe579bec731',
    'ユーザーA5', 'a5@shogun-trade.co', 'a5user',
    '000-0000-0000', NULL, NULL, 'その他', false, 'a5user',
    'https://shogun-trade.vercel.app/register?ref=a5user',
    '2025-06-24 11:05:38.783523+00', NOW()
);

-- 9. A5@shogun-trade.co
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    '901260bc-d2ed-4eb5-bed9-714f99c81693',
    'ユーザーA5UP', 'A5@shogun-trade.co', 'A5user',
    '000-0000-0000', NULL, NULL, 'その他', false, 'A5user',
    'https://shogun-trade.vercel.app/register?ref=A5user',
    '2025-06-26 04:20:09.784831+00', NOW()
);

-- 10. a6@shogun-trade.com
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    '1cc249e9-d5f2-4f5d-a126-9944449a7b77',
    'ユーザーA6', 'a6@shogun-trade.com', 'a6user',
    '000-0000-0000', NULL, NULL, 'その他', false, 'a6user',
    'https://shogun-trade.vercel.app/register?ref=a6user',
    '2025-06-24 11:05:39.449441+00', NOW()
);

SELECT 'BATCH 1 COMPLETED - 10 independent accounts created!' as batch1_status;

-- 確認クエリ
SELECT 'Independent accounts batch 1 verification:' as verification;
SELECT id, name, email, user_id FROM users 
WHERE id IN (
    '8e1edcf1-eded-40a1-8c11-a3adb771fd4b',
    '823d7463-6990-4a82-bc7a-d950bc3e3bb7',
    '85ba8cc8-ba0d-4e46-9077-bc024897ba3f',
    '7ced2f89-3d8a-4b21-aab6-a5e7d4393c73',
    'b161fbed-037f-4a47-a223-d8752e8c8c9d',
    '3b4f4059-b138-4e49-9be2-93481e1b2b74',
    '9a495c71-00e0-4bb8-b65d-8eb98c578344',
    '8815010c-6be0-48df-a255-8fe579bec731',
    '901260bc-d2ed-4eb5-bed9-714f99c81693',
    '1cc249e9-d5f2-4f5d-a126-9944449a7b77'
);

SELECT 'SUCCESS: First 10 independent accounts ready for login!' as success_message;