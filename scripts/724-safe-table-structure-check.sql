-- 安全なテーブル構造確認 - ユーザー・NFT情報は絶対に保護

-- 1. daily_rewardsテーブルの構造を確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
ORDER BY ordinal_position;

-- 2. reward_applicationsテーブルの構造を確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'reward_applications' 
ORDER BY ordinal_position;

-- 3. user_nftsテーブルの構造を確認（保護対象）
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_nfts' 
ORDER BY ordinal_position;

-- 4. usersテーブルの構造を確認（保護対象）
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

-- 5. nftsテーブルの構造を確認（保護対象）
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'nfts' 
ORDER BY ordinal_position;

SELECT 'Table structure check completed - User and NFT data will be protected' as status;
