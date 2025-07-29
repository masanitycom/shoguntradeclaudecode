-- テーブル構造の詳細確認

-- user_nfts テーブルの構造確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_nfts' 
ORDER BY ordinal_position;

-- group_weekly_rates テーブルの構造確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates' 
ORDER BY ordinal_position;

-- daily_rewards テーブルの構造確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
ORDER BY ordinal_position;

-- 制約の確認
SELECT 
    constraint_name, 
    constraint_type 
FROM information_schema.table_constraints 
WHERE table_name = 'group_weekly_rates';

-- サンプルデータの確認
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
