-- テーブル構造の詳細確認

-- group_weekly_rates テーブルの構造確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates' 
ORDER BY ordinal_position;

-- daily_rewards テーブルの構造確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
ORDER BY ordinal_position;

-- user_nfts テーブルの構造確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'user_nfts' 
ORDER BY ordinal_position;

-- 制約の確認
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    tc.is_deferrable,
    tc.initially_deferred
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'group_weekly_rates'
ORDER BY tc.constraint_type, tc.constraint_name;

-- サンプルデータの確認
SELECT 
    'user_nfts' as table_name,
    COUNT(*) as record_count
FROM user_nfts
UNION ALL
SELECT 
    'group_weekly_rates' as table_name,
    COUNT(*) as record_count
FROM group_weekly_rates
UNION ALL
SELECT 
    'daily_rewards' as table_name,
    COUNT(*) as record_count
FROM daily_rewards;

-- user_nfts のサンプルデータ（最初の3件）
SELECT 
    id,
    user_id,
    nft_id,
    purchase_price,
    current_investment,
    total_earned,
    max_earning,
    is_active
FROM user_nfts 
LIMIT 3;

SELECT 'テーブル構造確認完了' as status;
