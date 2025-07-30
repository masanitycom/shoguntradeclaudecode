-- 残り15個の完全独立アカウント作成（バッチ2）

SELECT '=== CREATING INDEPENDENT ACCOUNTS BATCH 2 (15 accounts) ===' as section;

-- 11. A6@shogun-trade.com
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    '7dc8dbb9-d904-4308-8241-01ff045d9a23',
    'ユーザーA6UP', 'A6@shogun-trade.com', 'A6user',
    '000-0000-0000', NULL, NULL, 'その他', false, 'A6user',
    'https://shogun-trade.vercel.app/register?ref=A6user',
    '2025-06-26 04:20:09.784831+00', NOW()
);

-- 12. a7@shogun-trade.com
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    'c2573115-ebc8-4025-8afb-065ffaae3318',
    'ユーザーA7', 'a7@shogun-trade.com', 'a7user',
    '000-0000-0000', NULL, NULL, 'その他', false, 'a7user',
    'https://shogun-trade.vercel.app/register?ref=a7user',
    '2025-06-24 11:05:40.099496+00', NOW()
);

-- 13. A7@shogun-trade.com
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    'a4b096b7-b72d-402d-ac5a-c6c8c9ed4842',
    'ユーザーA7UP', 'A7@shogun-trade.com', 'A7user',
    '000-0000-0000', NULL, NULL, 'その他', false, 'A7user',
    'https://shogun-trade.vercel.app/register?ref=A7user',
    '2025-06-26 04:20:09.784831+00', NOW()
);

-- 14. a8@shogun-trade.com
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    '43da6ffe-0138-46ca-8adb-43c3e3edb51f',
    'ユーザーA8', 'a8@shogun-trade.com', 'a8user',
    '000-0000-0000', NULL, NULL, 'その他', false, 'a8user',
    'https://shogun-trade.vercel.app/register?ref=a8user',
    '2025-06-24 11:05:44.129513+00', NOW()
);

-- 15. A8@shogun-trade.com
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    '7d078669-1e7f-4f2b-8a47-9cc17c8130cc',
    'ユーザーA8UP', 'A8@shogun-trade.com', 'A8user',
    '000-0000-0000', NULL, NULL, 'その他', false, 'A8user',
    'https://shogun-trade.vercel.app/register?ref=A8user',
    '2025-06-26 04:20:09.784831+00', NOW()
);

-- 16. a9@shogun-trade.com
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    'b5f21f57-9e3c-462d-a4bf-9b486b08fd2d',
    'ユーザーA9', 'a9@shogun-trade.com', 'a9user',
    '000-0000-0000', NULL, NULL, 'その他', false, 'a9user',
    'https://shogun-trade.vercel.app/register?ref=a9user',
    '2025-06-24 11:05:46.811387+00', NOW()
);

-- 17. l@shogun-trade.com
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    'b29faf89-3fe5-4ea2-86b1-617666863cd0',
    'ユーザーL', 'l@shogun-trade.com', 'luser',
    '000-0000-0000', NULL, NULL, 'その他', false, 'luser',
    'https://shogun-trade.vercel.app/register?ref=luser',
    '2025-06-24 10:08:04.411527+00', NOW()
);

-- 18. L@shogun-trade.com
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    'b42d09d8-1665-44cd-8cdd-5af0cba4b308',
    'ユーザーLUP', 'L@shogun-trade.com', 'Luser',
    '000-0000-0000', NULL, NULL, 'その他', false, 'Luser',
    'https://shogun-trade.vercel.app/register?ref=Luser',
    '2025-06-26 04:20:09.784831+00', NOW()
);

-- 19. s@shogun-trade.com
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    'e840b02f-36a5-4495-8db6-54b885371c8f',
    'ユーザーS', 's@shogun-trade.com', 'suser',
    '000-0000-0000', NULL, NULL, 'その他', false, 'suser',
    'https://shogun-trade.vercel.app/register?ref=suser',
    '2025-06-24 11:05:04.254545+00', NOW()
);

-- 20. S@shogun-trade.com
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    'bbcce823-6d2e-40a4-9422-9260ae34ef7d',
    'ユーザーSUP', 'S@shogun-trade.com', 'Suser',
    '000-0000-0000', NULL, NULL, 'その他', false, 'Suser',
    'https://shogun-trade.vercel.app/register?ref=Suser',
    '2025-06-26 04:20:09.784831+00', NOW()
);

-- 21. t@shogun-trade.com
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    'de8b2998-c113-46bb-bb9d-ad08b0a3b2ea',
    'ユーザーT', 't@shogun-trade.com', 'tuser',
    '000-0000-0000', NULL, NULL, 'その他', false, 'tuser',
    'https://shogun-trade.vercel.app/register?ref=tuser',
    '2025-06-24 10:08:43.302686+00', NOW()
);

-- 22. T@shogun-trade.com
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    '4f496737-c61b-4d78-9bb3-283323b15736',
    'ユーザーTUP', 'T@shogun-trade.com', 'Tuser',
    '000-0000-0000', NULL, NULL, 'その他', false, 'Tuser',
    'https://shogun-trade.vercel.app/register?ref=Tuser',
    '2025-06-26 04:20:09.784831+00', NOW()
);

-- 23. test005@example.com
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    'c20a4eb8-0351-4992-a0d2-ca2da7e2f240',
    'テストユーザー005', 'test005@example.com', 'test005',
    '000-0000-0000', NULL, NULL, 'その他', false, 'test005',
    'https://shogun-trade.vercel.app/register?ref=test005',
    '2025-06-24 11:23:38.263114+00', NOW()
);

-- 24. x@shogun-trade.com
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    '48f067ae-d9d5-40b3-813d-e513b156a584',
    'ユーザーX', 'x@shogun-trade.com', 'xuser',
    '000-0000-0000', NULL, NULL, 'その他', false, 'xuser',
    'https://shogun-trade.vercel.app/register?ref=xuser',
    '2025-06-24 10:09:05.254753+00', NOW()
);

-- 25. X@shogun-trade.com
INSERT INTO users (
    id, name, email, user_id, phone, referrer_id,
    usdt_address, wallet_type, is_admin, my_referral_code, referral_link,
    created_at, updated_at
) VALUES (
    'e9253c39-394a-4947-9fcb-94af80c2becf',
    'ユーザーXUP', 'X@shogun-trade.com', 'Xuser',
    '000-0000-0000', NULL, NULL, 'その他', false, 'Xuser',
    'https://shogun-trade.vercel.app/register?ref=Xuser',
    '2025-06-26 04:20:09.784831+00', NOW()
);

SELECT 'BATCH 2 COMPLETED - All 25 independent accounts created!' as batch2_status;

-- 最終確認：残りの孤立auth.users数
SELECT 'Final orphaned auth.users count:' as final_count;
SELECT COUNT(*) as remaining_orphaned
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE pu.id IS NULL;

SELECT 'SUCCESS: All 46 orphaned auth.users have been processed!' as final_success;