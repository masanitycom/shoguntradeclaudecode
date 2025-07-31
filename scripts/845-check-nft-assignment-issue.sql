-- NFT付与エラーの原因調査

SELECT '=== NFT付与エラー調査 ===' as section;

-- 1. user_nftsテーブルの制約確認
SELECT 'user_nftsテーブル制約:' as constraints;
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    tc.table_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'user_nfts'
ORDER BY tc.constraint_type, tc.constraint_name;

-- 2. RLS (Row Level Security) ポリシー確認
SELECT 'RLSポリシー確認:' as rls_policies;
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'user_nfts'
ORDER BY policyname;

-- 3. テーブル権限確認
SELECT 'テーブル権限:' as permissions;
SELECT 
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.role_table_grants
WHERE table_name = 'user_nfts'
  AND table_schema = 'public';

-- 4. 現在のuser_nftsのサンプルデータ確認
SELECT 'user_nftsサンプル:' as sample_data;
SELECT 
    id,
    user_id,
    nft_id,
    purchase_date,
    current_investment,
    is_active,
    created_at
FROM user_nfts
ORDER BY created_at DESC
LIMIT 5;

-- 5. nftsテーブルの利用可能なNFT確認
SELECT '利用可能なNFT:' as available_nfts;
SELECT 
    id,
    name,
    price,
    daily_rate_limit,
    is_special,
    is_active
FROM nfts
WHERE is_active = true
ORDER BY price
LIMIT 10;

-- 6. 特定ユーザーの既存NFT確認（重複チェック）
SELECT '22人の実ユーザーの現在のNFT状況:' as real_users_nfts;
SELECT 
    u.name,
    u.user_id,
    COUNT(un.id) as nft_count,
    ARRAY_AGG(n.name) as nft_names
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
LEFT JOIN nfts n ON un.nft_id = n.id
WHERE u.name IN (
    'サカイユカ3', 'ササキジュンコ', 'ヤタガワタクミ', 'オオクボユイ', 
    'ウチダハルナ', 'カタオカマサアキ', 'キムラリョウタ', 'コバヤシヨウスケ', 
    'サトウアイ', 'スギモトタロウ', 'タナカヒロシ', 'ヤマダミキ', 
    'イシザキイヅミ002', 'ウエハラケンタ', 'エンドウサヤカ', 'オカダユミ', 
    'カトウノリコ', 'キタムラタクヤ', 'コンドウミユキ', 'サイトウカナ', 
    'タケウチリナ', 'ヨシダマコト'
)
GROUP BY u.name, u.user_id
ORDER BY u.name;

SELECT '=== 調査完了 ===' as status;