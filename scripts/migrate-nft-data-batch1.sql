-- バッチ1のNFTデータを大文字版から小文字版に移行

SELECT '=== MIGRATING NFT DATA BATCH 1 ===' as section;

-- まず大文字版にNFTデータがあるか確認
SELECT 'Checking NFT data in uppercase accounts:' as nft_check;
SELECT 
    u.email as uppercase_email,
    u.id as uppercase_id,
    u.name,
    COUNT(un.id) as nft_count,
    SUM(un.current_investment::numeric) as total_investment
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE u.id IN (
    '7b5ca448-0e26-4582-bac1-141471f981cb',  -- B@shogun-trade.com
    '800bc8ba-a073-4050-8f1e-a76d38de5f74',  -- C@shogun-trade.com
    '23447bfd-fad3-463d-bd34-0289b842cd4a',  -- D@shogun-trade.com
    'c9aaeb8f-7a92-445c-8529-0a13c50240a0',  -- E@shogun-trade.com
    '0c15fe33-7ee3-4660-9bd5-0959d32f13d7'   -- F@shogun-trade.com
)
GROUP BY u.email, u.id, u.name
ORDER BY u.email;

-- NFTデータを小文字版に移行
-- 1. B@shogun-trade.com → b@shogun-trade.com
UPDATE user_nfts 
SET user_id = 'b6647604-8baa-4158-be6c-10ed45ac7bc5'
WHERE user_id = '7b5ca448-0e26-4582-bac1-141471f981cb' AND is_active = true;

-- 2. C@shogun-trade.com → c@shogun-trade.com
UPDATE user_nfts 
SET user_id = 'd898dae2-57b6-48d2-ae12-27a0fa9d7c52'
WHERE user_id = '800bc8ba-a073-4050-8f1e-a76d38de5f74' AND is_active = true;

-- 3. D@shogun-trade.com → d@shogun-trade.com
UPDATE user_nfts 
SET user_id = 'fdbbfcd5-80a8-4c59-b9bf-68684d56bd03'
WHERE user_id = '23447bfd-fad3-463d-bd34-0289b842cd4a' AND is_active = true;

-- 4. E@shogun-trade.com → e@shogun-trade.com
UPDATE user_nfts 
SET user_id = '90ee9886-1149-4fd9-bd7c-7f3b611be5b1'
WHERE user_id = 'c9aaeb8f-7a92-445c-8529-0a13c50240a0' AND is_active = true;

-- 5. F@shogun-trade.com → f@shogun-trade.com
UPDATE user_nfts 
SET user_id = 'bc5acf81-0d47-4485-b456-3143ff493b24'
WHERE user_id = '0c15fe33-7ee3-4660-9bd5-0959d32f13d7' AND is_active = true;

-- daily_rewardsも移行
UPDATE daily_rewards 
SET user_id = 'b6647604-8baa-4158-be6c-10ed45ac7bc5'
WHERE user_id = '7b5ca448-0e26-4582-bac1-141471f981cb';

UPDATE daily_rewards 
SET user_id = 'd898dae2-57b6-48d2-ae12-27a0fa9d7c52'
WHERE user_id = '800bc8ba-a073-4050-8f1e-a76d38de5f74';

UPDATE daily_rewards 
SET user_id = 'fdbbfcd5-80a8-4c59-b9bf-68684d56bd03'
WHERE user_id = '23447bfd-fad3-463d-bd34-0289b842cd4a';

UPDATE daily_rewards 
SET user_id = '90ee9886-1149-4fd9-bd7c-7f3b611be5b1'
WHERE user_id = 'c9aaeb8f-7a92-445c-8529-0a13c50240a0';

UPDATE daily_rewards 
SET user_id = 'bc5acf81-0d47-4485-b456-3143ff493b24'
WHERE user_id = '0c15fe33-7ee3-4660-9bd5-0959d32f13d7';

SELECT 'BATCH 1 NFT MIGRATION COMPLETED!' as migration_status;

-- 移行結果の確認
SELECT 'Migration verification:' as verification;
SELECT 
    u.email as lowercase_email,
    u.name,
    u.user_id,
    COUNT(un.id) as nft_count,
    SUM(un.current_investment::numeric) as total_investment
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE u.id IN (
    'b6647604-8baa-4158-be6c-10ed45ac7bc5',  -- b@shogun-trade.com
    'd898dae2-57b6-48d2-ae12-27a0fa9d7c52',  -- c@shogun-trade.com
    'fdbbfcd5-80a8-4c59-b9bf-68684d56bd03',  -- d@shogun-trade.com
    '90ee9886-1149-4fd9-bd7c-7f3b611be5b1',  -- e@shogun-trade.com
    'bc5acf81-0d47-4485-b456-3143ff493b24'   -- f@shogun-trade.com
)
GROUP BY u.email, u.name, u.user_id
ORDER BY u.email;

SELECT 'SUCCESS: First 5 lowercase accounts now have their NFT data!' as success_message;