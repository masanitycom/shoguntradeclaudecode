-- NFTデータを認証同期済みアカウントに移行

SELECT '=== MIGRATING NFT DATA TO AUTH-SYNCED ACCOUNTS ===' as section;

-- Step 1: Tokusana371@gmail.com のNFTを tokusana371@gmail.com に移行
UPDATE user_nfts 
SET user_id = '359f44c4-507e-4867-b25d-592f98962145'  -- tokusana371@gmail.com のauth ID
WHERE user_id = '4bfb2fd3-5886-4a92-b31a-fe83d0a91e50'  -- Tokusana371@gmail.com のID
  AND is_active = true;

-- Step 2: A3@shogun-trade.com のNFTを a3@shogun-trade.com に移行
UPDATE user_nfts 
SET user_id = '9ed30a48-e5cd-483b-8d79-c84fb5248d48'  -- a3@shogun-trade.com のauth ID
WHERE user_id = '176bcbce-3cca-4838-b714-681a901a7274'  -- A3@shogun-trade.com のID
  AND is_active = true;

-- Step 3: 関連するdaily_rewardsも移行
UPDATE daily_rewards 
SET user_id = '359f44c4-507e-4867-b25d-592f98962145'
WHERE user_id = '4bfb2fd3-5886-4a92-b31a-fe83d0a91e50';

UPDATE daily_rewards 
SET user_id = '9ed30a48-e5cd-483b-8d79-c84fb5248d48'
WHERE user_id = '176bcbce-3cca-4838-b714-681a901a7274';

-- 移行完了確認
SELECT 'NFT MIGRATION COMPLETED!' as status;

-- Step 4: 移行結果の確認
SELECT '=== MIGRATION VERIFICATION ===' as verification;

-- mook0214 (tokusana371@gmail.com) の最終状態
SELECT 'mook0214 final state:' as mook_final;
SELECT 
    u.name,
    u.email,
    u.user_id,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = u.id AND is_active = true) as nft_count,
    (SELECT SUM(current_investment::numeric) FROM user_nfts WHERE user_id = u.id AND is_active = true) as total_investment
FROM users u
WHERE u.id = '359f44c4-507e-4867-b25d-592f98962145';

-- Zuurin123002 (a3@shogun-trade.com) の最終状態
SELECT 'Zuurin123002 final state:' as zuurin_final;
SELECT 
    u.name,
    u.email,
    u.user_id,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = u.id AND is_active = true) as nft_count,
    (SELECT SUM(current_investment::numeric) FROM user_nfts WHERE user_id = u.id AND is_active = true) as total_investment
FROM users u
WHERE u.id = '9ed30a48-e5cd-483b-8d79-c84fb5248d48';

-- 大文字版アカウントのNFTが0になったか確認
SELECT 'Uppercase accounts should now have 0 NFTs:' as uppercase_check;
SELECT 
    u.email,
    (SELECT COUNT(*) FROM user_nfts WHERE user_id = u.id AND is_active = true) as remaining_nfts
FROM users u
WHERE u.email IN ('Tokusana371@gmail.com', 'A3@shogun-trade.com');

SELECT 'SUCCESS: NFT data migrated to auth-synced accounts!' as success_message;