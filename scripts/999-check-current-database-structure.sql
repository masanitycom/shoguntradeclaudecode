-- 現在のデータベース構造とデータの確認
-- 既存データを壊さないよう、READ ONLYで確認

-- 1. 主要テーブルの構造確認
SELECT 'USERS テーブル構造' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

SELECT 'USER_NFTS テーブル構造' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_nfts' 
ORDER BY ordinal_position;

SELECT 'NFTS テーブル構造' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'nfts' 
ORDER BY ordinal_position;

SELECT 'DAILY_REWARDS テーブル構造' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
ORDER BY ordinal_position;

-- 2. 既存データの確認
SELECT 'ユーザー数確認' as info;
SELECT COUNT(*) as total_users FROM users;

SELECT 'アクティブNFT数確認' as info;
SELECT COUNT(*) as active_nfts FROM user_nfts WHERE is_active = true;

SELECT 'USER_NFTSのサンプルデータ（最新5件）' as info;
SELECT 
    un.id,
    u.name as user_name,
    u.user_id,
    n.name as nft_name,
    un.purchase_date,
    un.operation_start_date,
    un.current_investment,
    un.total_earned,
    un.is_active,
    un.created_at
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true
ORDER BY un.created_at DESC
LIMIT 5;

SELECT 'OPERATION_START_DATEの設定状況' as info;
SELECT 
    COUNT(*) as total_active_nfts,
    COUNT(operation_start_date) as with_operation_date,
    COUNT(*) - COUNT(operation_start_date) as missing_operation_date,
    ROUND(COUNT(operation_start_date) * 100.0 / COUNT(*), 2) as completion_percentage
FROM user_nfts 
WHERE is_active = true;

SELECT '運用開始日の分布' as info;
SELECT 
    operation_start_date,
    COUNT(*) as nft_count
FROM user_nfts 
WHERE is_active = true 
  AND operation_start_date IS NOT NULL
GROUP BY operation_start_date
ORDER BY operation_start_date DESC
LIMIT 10;

-- 3. 既存の関数確認
SELECT '既存のoperation_start_date関連関数' as info;
SELECT 
    proname as function_name,
    prosrc as function_source
FROM pg_proc 
WHERE proname LIKE '%operation%' 
   OR proname LIKE '%start%date%'
   OR prosrc LIKE '%operation_start_date%';

-- 4. 既存のトリガー確認
SELECT 'USER_NFTSテーブルのトリガー' as info;
SELECT 
    tgname as trigger_name,
    tgtype,
    tgenabled
FROM pg_trigger 
WHERE tgrelid = 'user_nfts'::regclass;

-- 5. 最近のデイリーリワード確認
SELECT '最近のデイリーリワード（最新5件）' as info;
SELECT 
    dr.reward_date,
    u.name as user_name,
    dr.reward_amount,
    dr.daily_rate,
    dr.created_at
FROM daily_rewards dr
JOIN users u ON dr.user_id = u.id
ORDER BY dr.created_at DESC
LIMIT 5;

-- 6. 購入日と運用開始日の関係確認
SELECT '購入日と運用開始日の関係確認' as info;
SELECT 
    u.name as user_name,
    n.name as nft_name,
    un.purchase_date,
    un.operation_start_date,
    EXTRACT(DOW FROM un.operation_start_date) as operation_day_of_week,
    (un.operation_start_date - un.purchase_date) as days_difference
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true 
  AND un.purchase_date IS NOT NULL 
  AND un.operation_start_date IS NOT NULL
ORDER BY un.purchase_date DESC
LIMIT 10;