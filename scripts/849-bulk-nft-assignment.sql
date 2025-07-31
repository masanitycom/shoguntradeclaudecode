-- 残り21人の実ユーザーにNFT一括付与

SELECT '=== 実ユーザーNFT一括付与 ===' as section;

-- 1. NFTが必要な実ユーザー確認
SELECT 'NFT付与対象ユーザー:' as target_users;
SELECT 
    u.id,
    u.name,
    u.user_id,
    COUNT(un.id) as current_nfts
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE u.name IN (
    'ササキジュンコ', 'ヤタガワタクミ', 'オオクボユイ', 
    'ウチダハルナ', 'カタオカマサアキ', 'キムラリョウタ', 'コバヤシヨウスケ', 
    'サトウアイ', 'スギモトタロウ', 'タナカヒロシ', 'ヤマダミキ', 
    'イシザキイヅミ002', 'ウエハラケンタ', 'エンドウサヤカ', 'オカダユミ', 
    'カトウノリコ', 'キタムラタクヤ', 'コンドウミユキ', 'サイトウカナ', 
    'タケウチリナ', 'ヨシダマコト'
)
GROUP BY u.id, u.name, u.user_id
HAVING COUNT(un.id) = 0
ORDER BY u.name;

-- 2. SHOGUN NFT 1000の情報確認
SELECT 'NFT情報:' as nft_info;
SELECT 
    id,
    name,
    price,
    daily_rate_limit
FROM nfts
WHERE name = 'SHOGUN NFT 1000'
  AND is_active = true;

-- 3. 一括NFT付与実行
SELECT 'NFT一括付与実行中...' as bulk_insert;
INSERT INTO user_nfts (
    user_id,
    nft_id,
    purchase_date,
    purchase_price,
    current_investment,
    max_earning,
    total_earned,
    is_active
) 
SELECT 
    u.id as user_id,
    n.id as nft_id,
    '2025-02-03'::timestamp with time zone as purchase_date,
    n.price as purchase_price,
    n.price as current_investment,
    n.price * 3 as max_earning,
    0.00 as total_earned,
    true as is_active
FROM users u
CROSS JOIN nfts n
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE u.name IN (
    'ササキジュンコ', 'ヤタガワタクミ', 'オオクボユイ', 
    'ウチダハルナ', 'カタオカマサアキ', 'キムラリョウタ', 'コバヤシヨウスケ', 
    'サトウアイ', 'スギモトタロウ', 'タナカヒロシ', 'ヤマダミキ', 
    'イシザキイヅミ002', 'ウエハラケンタ', 'エンドウサヤカ', 'オカダユミ', 
    'カトウノリコ', 'キタムラタクヤ', 'コンドウミユキ', 'サイトウカナ', 
    'タケウチリナ', 'ヨシダマコト'
)
AND n.name = 'SHOGUN NFT 1000'
AND n.is_active = true
AND un.id IS NULL; -- 既存NFTがないユーザーのみ

-- 4. 付与結果確認
SELECT 'NFT付与結果:' as assignment_result;
SELECT 
    u.name as user_name,
    u.user_id,
    n.name as nft_name,
    un.purchase_price,
    un.current_investment,
    un.max_earning,
    un.created_at
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.name IN (
    'サカイユカ3', 'ササキジュンコ', 'ヤタガワタクミ', 'オオクボユイ', 
    'ウチダハルナ', 'カタオカマサアキ', 'キムラリョウタ', 'コバヤシヨウスケ', 
    'サトウアイ', 'スギモトタロウ', 'タナカヒロシ', 'ヤマダミキ', 
    'イシザキイヅミ002', 'ウエハラケンタ', 'エンドウサヤカ', 'オカダユミ', 
    'カトウノリコ', 'キタムラタクヤ', 'コンドウミユキ', 'サイトウカナ', 
    'タケウチリナ', 'ヨシダマコト'
)
AND un.is_active = true
ORDER BY u.name;

SELECT '=== 一括NFT付与完了 ===' as status;