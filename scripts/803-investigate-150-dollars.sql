-- SHOGUN NFT 1000 (Special)の$1.50獲得済み調査

SELECT '=== SHOGUN NFT 1000 (Special) - $1.50獲得済み調査 ===' as section;

-- 1. SHOGUN NFT 1000 (Special)の基本情報確認
SELECT 'SHOGUN NFT 1000 (Special) NFT基本情報:' as info;
SELECT 
    id,
    name,
    price,
    daily_rate_limit,
    image_url,
    is_special
FROM nfts 
WHERE name LIKE '%SHOGUN NFT 1000%' OR price = 1000;

-- 2. このNFTを保有しているユーザー情報
SELECT 'NFT保有ユーザー情報:' as info;
SELECT 
    un.id as user_nft_id,
    un.user_id,
    u.name,
    u.email,
    un.nft_id,
    un.current_investment,
    un.total_earned,
    un.max_earning,
    un.purchase_date,
    un.operation_start_date,
    un.is_active
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE n.name LIKE '%SHOGUN NFT 1000%' OR n.price = 1000;

-- 3. daily_rewardsテーブルでの報酬記録確認
SELECT 'Daily rewards記録:' as info;
SELECT 
    dr.id,
    dr.user_id,
    u.name,
    dr.user_nft_id,
    dr.reward_amount,
    dr.reward_date,
    dr.weekly_rate,
    dr.is_claimed,
    dr.created_at
FROM daily_rewards dr
JOIN users u ON dr.user_id = u.id
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
WHERE (n.name LIKE '%SHOGUN NFT 1000%' OR n.price = 1000)
ORDER BY dr.reward_date DESC;

-- 4. user_nftsのtotal_earnedが1.50の具体的な記録
SELECT 'Total earned = 1.50の具体的なレコード:' as info;
SELECT 
    un.id as user_nft_id,
    un.user_id,
    u.name,
    u.email,
    n.name as nft_name,
    un.total_earned,
    un.purchase_date,
    un.operation_start_date,
    un.created_at,
    un.updated_at
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.total_earned = 1.50;

-- 5. 最近のデータ更新履歴確認
SELECT 'Recent updates on user_nfts:' as info;
SELECT 
    un.id,
    un.user_id,
    u.name,
    n.name as nft_name,
    un.total_earned,
    un.updated_at
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.updated_at > '2025-01-30'
ORDER BY un.updated_at DESC;

SELECT 'Investigation complete - Check if $1.50 should be cleared' as conclusion;