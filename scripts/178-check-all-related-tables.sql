-- 関連テーブルの構造確認

-- 1. users テーブルの構造確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

-- 2. user_nfts テーブルの構造確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_nfts' 
ORDER BY ordinal_position;

-- 3. users テーブルのサンプルデータ（referrer_id関連）
SELECT 
    id,
    name,
    user_id,
    referrer_id,
    is_admin
FROM users 
WHERE referrer_id IS NOT NULL
LIMIT 5;

-- 4. user_nfts テーブルのサンプルデータ
SELECT 
    id,
    user_id,
    nft_id,
    current_investment,
    is_active
FROM user_nfts 
WHERE is_active = true
LIMIT 5;

-- 5. NFTを持っているユーザー数の確認
SELECT 
    COUNT(DISTINCT user_id) as users_with_nfts,
    SUM(current_investment) as total_investment
FROM user_nfts 
WHERE is_active = true;

-- 6. 紹介関係があるユーザー数の確認
SELECT 
    COUNT(*) as users_with_referrer
FROM users 
WHERE referrer_id IS NOT NULL AND is_admin = false;
