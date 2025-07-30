-- 大文字版アカウントのNFTデータ確認と移行

SELECT '=== UPPERCASE ACCOUNTS NFT DATA CHECK ===' as section;

-- Tokusana371@gmail.com (大文字版) のNFTデータ確認
SELECT 'Tokusana371@gmail.com (uppercase) NFT data:' as tokusana_uppercase;
SELECT 
    un.user_id,
    u.name as owner_name,
    u.email as owner_email,
    u.user_id as public_user_id,
    un.current_investment,
    un.is_active
FROM user_nfts un
LEFT JOIN users u ON un.user_id = u.id
WHERE u.email = 'Tokusana371@gmail.com' 
  AND un.is_active = true;

-- A3@shogun-trade.com (大文字版) のNFTデータ確認
SELECT 'A3@shogun-trade.com (uppercase) NFT data:' as a3_uppercase;
SELECT 
    un.user_id,
    u.name as owner_name,
    u.email as owner_email,
    u.user_id as public_user_id,
    un.current_investment,
    un.is_active
FROM user_nfts un
LEFT JOIN users u ON un.user_id = u.id
WHERE u.email = 'A3@shogun-trade.com' 
  AND un.is_active = true;

-- NFTデータの移行が必要かチェック
SELECT 'NFT migration needed:' as migration_check;
SELECT 
    'Tokusana371 → tokusana371' as migration_type,
    (SELECT COUNT(*) FROM user_nfts un JOIN users u ON un.user_id = u.id 
     WHERE u.email = 'Tokusana371@gmail.com' AND un.is_active = true) as source_nft_count,
    (SELECT COUNT(*) FROM user_nfts un JOIN users u ON un.user_id = u.id 
     WHERE u.email = 'tokusana371@gmail.com' AND un.is_active = true) as target_nft_count

UNION ALL

SELECT 
    'A3 → a3' as migration_type,
    (SELECT COUNT(*) FROM user_nfts un JOIN users u ON un.user_id = u.id 
     WHERE u.email = 'A3@shogun-trade.com' AND un.is_active = true) as source_nft_count,
    (SELECT COUNT(*) FROM user_nfts un JOIN users u ON un.user_id = u.id 
     WHERE u.email = 'a3@shogun-trade.com' AND un.is_active = true) as target_nft_count;