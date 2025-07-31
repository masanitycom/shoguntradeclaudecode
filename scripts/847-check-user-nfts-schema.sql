-- user_nftsテーブルスキーマ確認

SELECT '=== user_nftsテーブル構造確認 ===' as section;

-- 1. テーブルの全カラム情報確認
SELECT 'user_nftsカラム情報:' as columns;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns
WHERE table_name = 'user_nfts'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. NOT NULL制約の確認
SELECT 'NOT NULL制約:' as not_null_constraints;
SELECT 
    column_name,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'user_nfts'
  AND table_schema = 'public'
  AND is_nullable = 'NO'
ORDER BY column_name;

-- 3. 現在のuser_nftsデータでpurchase_priceの状況確認
SELECT 'purchase_priceデータ状況:' as price_data;
SELECT 
    COUNT(*) as total_records,
    COUNT(purchase_price) as non_null_purchase_price,
    COUNT(*) - COUNT(purchase_price) as null_purchase_price,
    MIN(purchase_price) as min_price,
    MAX(purchase_price) as max_price,
    AVG(purchase_price) as avg_price
FROM user_nfts;

-- 4. purchase_priceがnullのレコード確認
SELECT 'purchase_priceがnullのレコード:' as null_records;
SELECT 
    id,
    user_id,
    nft_id,
    purchase_price,
    current_investment,
    created_at
FROM user_nfts
WHERE purchase_price IS NULL
LIMIT 10;

SELECT '=== スキーマ確認完了 ===' as status;