-- バッチ3のNFTデータを大文字版から小文字版に移行

SELECT '=== MIGRATING NFT DATA BATCH 3 (FINAL) ===' as section;

-- NFTデータを小文字版に移行
-- 14. P@shogun-trade.com → p@shogun-trade.com
UPDATE user_nfts 
SET user_id = '5bff5144-c714-4c94-89da-0413e5b2edee'
WHERE user_id = 'b1865f42-b846-4d07-9f59-f4a6bb1dbb42' AND is_active = true;

-- 15. Q@shogun-trade.com → q@shogun-trade.com
UPDATE user_nfts 
SET user_id = 'e6b81dac-915a-489d-8213-eb23c4f0f76d'
WHERE user_id = '6af12598-cff0-4cea-9d0e-9396518fbc10' AND is_active = true;

-- 16. R@shogun-trade.com → r@shogun-trade.com
UPDATE user_nfts 
SET user_id = '04183cb9-386e-4aa6-bda7-97d21cbfc287'
WHERE user_id = '347364df-69c0-4f80-b07e-6ed1c469fd5c' AND is_active = true;

-- 17. U@shogun-trade.com → u@shogun-trade.com
UPDATE user_nfts 
SET user_id = 'c8e1b8f7-c687-4765-9856-3fe07c083b67'
WHERE user_id = 'f40d7304-6602-4f1a-b328-4a57bb913a1c' AND is_active = true;

-- 18. V@shogun-trade.com → v@shogun-trade.com
UPDATE user_nfts 
SET user_id = 'd460ff12-87ce-4474-8dcf-6040565951ec'
WHERE user_id = '5c3bf22c-791e-49ff-837d-708ef3cf5a6f' AND is_active = true;

-- 19. W@shogun-trade.com → w@shogun-trade.com
UPDATE user_nfts 
SET user_id = '0ebf4469-a96a-4f1e-a16c-f3613f8beb22'
WHERE user_id = 'f2a6a70b-1067-4ff8-9451-bec65717ed5b' AND is_active = true;

-- 20. Y@shogun-trade.com → y@shogun-trade.com
UPDATE user_nfts 
SET user_id = '1a252fa3-54ee-4983-a476-75bb90f78e2b'
WHERE user_id = '3dc28c08-3ff3-4932-b340-cbf4036572fd' AND is_active = true;

-- 21. Z@shogun-trade.com → z@shogun-trade.com
UPDATE user_nfts 
SET user_id = '3c142554-2169-441a-a78f-bdf034ad417f'
WHERE user_id = 'f541e550-9b2d-4dc3-80ce-0f7500b7ab80' AND is_active = true;

-- daily_rewardsも移行
UPDATE daily_rewards SET user_id = '5bff5144-c714-4c94-89da-0413e5b2edee' WHERE user_id = 'b1865f42-b846-4d07-9f59-f4a6bb1dbb42';
UPDATE daily_rewards SET user_id = 'e6b81dac-915a-489d-8213-eb23c4f0f76d' WHERE user_id = '6af12598-cff0-4cea-9d0e-9396518fbc10';
UPDATE daily_rewards SET user_id = '04183cb9-386e-4aa6-bda7-97d21cbfc287' WHERE user_id = '347364df-69c0-4f80-b07e-6ed1c469fd5c';
UPDATE daily_rewards SET user_id = 'c8e1b8f7-c687-4765-9856-3fe07c083b67' WHERE user_id = 'f40d7304-6602-4f1a-b328-4a57bb913a1c';
UPDATE daily_rewards SET user_id = 'd460ff12-87ce-4474-8dcf-6040565951ec' WHERE user_id = '5c3bf22c-791e-49ff-837d-708ef3cf5a6f';
UPDATE daily_rewards SET user_id = '0ebf4469-a96a-4f1e-a16c-f3613f8beb22' WHERE user_id = 'f2a6a70b-1067-4ff8-9451-bec65717ed5b';
UPDATE daily_rewards SET user_id = '1a252fa3-54ee-4983-a476-75bb90f78e2b' WHERE user_id = '3dc28c08-3ff3-4932-b340-cbf4036572fd';
UPDATE daily_rewards SET user_id = '3c142554-2169-441a-a78f-bdf034ad417f' WHERE user_id = 'f541e550-9b2d-4dc3-80ce-0f7500b7ab80';

SELECT 'BATCH 3 NFT MIGRATION COMPLETED!' as migration_status;

-- 全21ペアの最終確認
SELECT 'ALL 21 PAIRS FINAL VERIFICATION:' as final_verification;
SELECT 
    u.email as lowercase_email,
    u.name,
    u.user_id,
    COUNT(un.id) as nft_count,
    SUM(un.current_investment::numeric) as total_investment
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE u.email LIKE '%@shogun-trade.com' 
  AND u.email ~ '^[a-z]@shogun-trade\.com$'  -- 小文字のみ
GROUP BY u.email, u.name, u.user_id
ORDER BY u.email;

-- 孤立auth.usersの残り数確認
SELECT 'Remaining orphaned auth.users after pairs processing:' as remaining_orphans;
SELECT COUNT(*) as orphaned_count
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE pu.id IS NULL;

SELECT 'SUCCESS: All 21 pairs completed! Ready for independent accounts processing!' as success_message;