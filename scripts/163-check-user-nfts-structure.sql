-- user_nftsテーブルの構造を確認

-- 1. user_nftsテーブルの詳細構造
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

-- 2. user_nftsテーブルの制約確認
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    ccu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_name = 'user_nfts'
AND tc.table_schema = 'public';

-- 3. user_nftsテーブルのサンプルデータ
SELECT * FROM user_nfts LIMIT 5;

-- 4. daily_rewardsテーブルの構造も確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 5. nft_weekly_ratesテーブルの構造確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'nft_weekly_rates' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 6. nft_weekly_ratesのサンプルデータ
SELECT * FROM nft_weekly_rates WHERE week_number = 2 LIMIT 5;
