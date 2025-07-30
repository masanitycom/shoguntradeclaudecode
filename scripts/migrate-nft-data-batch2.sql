-- バッチ2のNFTデータを大文字版から小文字版に移行

SELECT '=== MIGRATING NFT DATA BATCH 2 ===' as section;

-- NFTデータを小文字版に移行
-- 6. G@shogun-trade.com → g@shogun-trade.com
UPDATE user_nfts 
SET user_id = 'ac6640ee-fdc0-42ab-8b6e-901cc02ef3ff'
WHERE user_id = 'd860ee09-a573-4f46-9754-275c3505dbb8' AND is_active = true;

-- 7. H@shogun-trade.com → h@shogun-trade.com
UPDATE user_nfts 
SET user_id = '1e18b500-5f7b-4a0d-9359-5a4cdc3c8e9c'
WHERE user_id = 'a74aebad-fff2-48f7-937d-900c9a3c871b' AND is_active = true;

-- 8. I@shogun-trade.com → i@shogun-trade.com
UPDATE user_nfts 
SET user_id = '6b280a65-608e-45a1-98b5-18c4811a05a1'
WHERE user_id = '6df11e9e-4791-4a5c-97ae-29f090e07b17' AND is_active = true;

-- 9. J@shogun-trade.com → j@shogun-trade.com
UPDATE user_nfts 
SET user_id = 'e7ed5406-f960-4277-9bd8-f6449db66f1b'
WHERE user_id = 'd09bc7cf-8a08-45bf-8451-5ccdb046028c' AND is_active = true;

-- 10. K@shogun-trade.com → k@shogun-trade.com
UPDATE user_nfts 
SET user_id = '3bf2cbcb-70e5-46bd-b7d5-07de361519f0'
WHERE user_id = 'f608668d-5b8c-4822-9bf4-48a677c88a1b' AND is_active = true;

-- 11. M@shogun-trade.com → m@shogun-trade.com
UPDATE user_nfts 
SET user_id = '89d7358b-a50d-4f2f-a79c-0b9c31fe51d4'
WHERE user_id = '1b42e0d1-118f-49e1-b648-da65304eec29' AND is_active = true;

-- 12. N@shogun-trade.com → n@shogun-trade.com
UPDATE user_nfts 
SET user_id = '9c55954a-510d-44ec-b8e0-8482514e8fa2'
WHERE user_id = '16008c8d-5d70-4006-807f-018c810a7cc4' AND is_active = true;

-- 13. O@shogun-trade.com → o@shogun-trade.com
UPDATE user_nfts 
SET user_id = '37026109-bd49-4a75-bce4-4826e0d300f1'
WHERE user_id = '56f9ad59-a7f8-40ac-94d9-e28e7ef9cdb3' AND is_active = true;

-- daily_rewardsも移行
UPDATE daily_rewards SET user_id = 'ac6640ee-fdc0-42ab-8b6e-901cc02ef3ff' WHERE user_id = 'd860ee09-a573-4f46-9754-275c3505dbb8';
UPDATE daily_rewards SET user_id = '1e18b500-5f7b-4a0d-9359-5a4cdc3c8e9c' WHERE user_id = 'a74aebad-fff2-48f7-937d-900c9a3c871b';
UPDATE daily_rewards SET user_id = '6b280a65-608e-45a1-98b5-18c4811a05a1' WHERE user_id = '6df11e9e-4791-4a5c-97ae-29f090e07b17';
UPDATE daily_rewards SET user_id = 'e7ed5406-f960-4277-9bd8-f6449db66f1b' WHERE user_id = 'd09bc7cf-8a08-45bf-8451-5ccdb046028c';
UPDATE daily_rewards SET user_id = '3bf2cbcb-70e5-46bd-b7d5-07de361519f0' WHERE user_id = 'f608668d-5b8c-4822-9bf4-48a677c88a1b';
UPDATE daily_rewards SET user_id = '89d7358b-a50d-4f2f-a79c-0b9c31fe51d4' WHERE user_id = '1b42e0d1-118f-49e1-b648-da65304eec29';
UPDATE daily_rewards SET user_id = '9c55954a-510d-44ec-b8e0-8482514e8fa2' WHERE user_id = '16008c8d-5d70-4006-807f-018c810a7cc4';
UPDATE daily_rewards SET user_id = '37026109-bd49-4a75-bce4-4826e0d300f1' WHERE user_id = '56f9ad59-a7f8-40ac-94d9-e28e7ef9cdb3';

SELECT 'BATCH 2 NFT MIGRATION COMPLETED!' as migration_status;

-- 移行結果の確認
SELECT 'Batch 2 migration verification:' as verification;
SELECT 
    u.email as lowercase_email,
    u.name,
    u.user_id,
    COUNT(un.id) as nft_count,
    SUM(un.current_investment::numeric) as total_investment
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE u.id IN (
    'ac6640ee-fdc0-42ab-8b6e-901cc02ef3ff',  -- g@shogun-trade.com
    '1e18b500-5f7b-4a0d-9359-5a4cdc3c8e9c',  -- h@shogun-trade.com
    '6b280a65-608e-45a1-98b5-18c4811a05a1',  -- i@shogun-trade.com
    'e7ed5406-f960-4277-9bd8-f6449db66f1b',  -- j@shogun-trade.com
    '3bf2cbcb-70e5-46bd-b7d5-07de361519f0',  -- k@shogun-trade.com
    '89d7358b-a50d-4f2f-a79c-0b9c31fe51d4',  -- m@shogun-trade.com
    '9c55954a-510d-44ec-b8e0-8482514e8fa2',  -- n@shogun-trade.com
    '37026109-bd49-4a75-bce4-4826e0d300f1'   -- o@shogun-trade.com
)
GROUP BY u.email, u.name, u.user_id
ORDER BY u.email;

SELECT 'SUCCESS: Batch 2 lowercase accounts now have their NFT data!' as success_message;