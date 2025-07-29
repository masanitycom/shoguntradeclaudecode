-- テーブル構造の確認

-- 1. daily_rewardsテーブルの構造確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. user_nftsテーブルの構造確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_nfts' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. reward_applicationsテーブルの構造確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'reward_applications' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. nft_purchase_applicationsテーブルの構造確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'nft_purchase_applications' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 5. user_rank_historyテーブルの構造確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_rank_history' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 6. tenka_bonus_distributionsテーブルの構造確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'tenka_bonus_distributions' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 7. 外部キー制約の確認
SELECT 
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    tc.constraint_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_schema = 'public'
AND ccu.table_name = 'users'
ORDER BY tc.table_name, kcu.column_name;
