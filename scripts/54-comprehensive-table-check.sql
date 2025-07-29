-- 全テーブル構造の包括的確認

SELECT '=== USERS テーブル構造確認 ===' as section;

-- usersテーブルの詳細構造
SELECT 
    column_name, 
    data_type, 
    character_maximum_length,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT '=== USERS テーブルのサンプルデータ ===' as section;

-- usersテーブルの実際のデータ確認（最初の3件）
SELECT 
    id,
    name,
    email,
    user_id,
    referral_code,
    my_referral_code,
    referral_link,
    wallet_address,
    wallet_type,
    is_admin,
    created_at
FROM users 
ORDER BY created_at DESC 
LIMIT 3;

SELECT '=== 紹介関連カラムの統計 ===' as section;

-- 紹介関連データの統計
SELECT 
    COUNT(*) as total_users,
    COUNT(referral_code) as users_with_referral_code,
    COUNT(my_referral_code) as users_with_my_referral_code,
    COUNT(referral_link) as users_with_referral_link,
    COUNT(wallet_address) as users_with_wallet_address
FROM users;

SELECT '=== NFT関連テーブル確認 ===' as section;

-- NFTsテーブル構造
SELECT 'NFTs table structure:' as info;
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'nfts' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- USER_NFTsテーブル構造
SELECT 'USER_NFTs table structure:' as info;
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_nfts' 
AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT '=== 管理者ユーザー確認 ===' as section;

-- 管理者ユーザーの確認
SELECT 
    name,
    user_id,
    email,
    is_admin,
    created_at
FROM users 
WHERE is_admin = true;

SELECT '=== 最近のユーザー登録状況 ===' as section;

-- 最近登録されたユーザー（上位10件）
SELECT 
    name,
    user_id,
    email,
    COALESCE(referral_code, 'なし') as referral_code,
    COALESCE(my_referral_code, 'なし') as my_referral_code,
    created_at
FROM users 
WHERE is_admin = false
ORDER BY created_at DESC 
LIMIT 10;

SELECT '=== データベース全体の健全性チェック ===' as section;

-- 重要なテーブルの存在確認
SELECT 
    table_name,
    CASE 
        WHEN table_name IN ('users', 'nfts', 'user_nfts', 'nft_purchase_applications', 'tasks', 'mlm_ranks') 
        THEN '✅ 重要テーブル'
        ELSE '📋 その他'
    END as importance
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;
