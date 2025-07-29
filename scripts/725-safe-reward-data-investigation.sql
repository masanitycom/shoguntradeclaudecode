-- 安全な報酬データ調査 - シンプル版

-- 1. daily_rewardsテーブルのデータ確認
SELECT 
    'daily_rewards' as table_name,
    COUNT(*) as record_count
FROM daily_rewards;

-- 2. reward_applicationsテーブルのデータ確認
SELECT 
    'reward_applications' as table_name,
    COUNT(*) as record_count
FROM reward_applications;

-- 3. ユーザー・NFT情報の保護確認
SELECT 
    'users' as table_name,
    COUNT(*) as record_count,
    'PROTECTED' as status
FROM users
UNION ALL
SELECT 
    'nfts' as table_name,
    COUNT(*) as record_count,
    'PROTECTED' as status
FROM nfts
UNION ALL
SELECT 
    'user_nfts' as table_name,
    COUNT(*) as record_count,
    'PROTECTED' as status
FROM user_nfts;

-- 4. 週利データの確認
SELECT 
    'group_weekly_rates' as table_name,
    COUNT(*) as record_count
FROM group_weekly_rates;

SELECT 'Safe investigation completed - All user and NFT data protected' as status;
