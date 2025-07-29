-- 🔍 SHOGUN TRADE システム包括診断
-- 全テーブル構造と関数の確認

-- 📊 基本テーブル構造確認
SELECT '🔍 テーブル定義確認' as info;

-- users テーブル構造
SELECT 
    '👥 users テーブル' as table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

-- nfts テーブル構造
SELECT 
    '🎨 nfts テーブル' as table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'nfts' 
ORDER BY ordinal_position;

-- user_nfts テーブル構造
SELECT 
    '💎 user_nfts テーブル' as table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_nfts' 
ORDER BY ordinal_position;

-- daily_rewards テーブル構造
SELECT 
    '💰 daily_rewards テーブル' as table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
ORDER BY ordinal_position;

-- group_weekly_rates テーブル構造
SELECT 
    '📈 group_weekly_rates テーブル' as table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates' 
ORDER BY ordinal_position;

-- daily_rate_groups テーブル構造
SELECT 
    '🎯 daily_rate_groups テーブル' as table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'daily_rate_groups' 
ORDER BY ordinal_position;

-- mlm_ranks テーブル構造
SELECT 
    '🏆 mlm_ranks テーブル' as table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'mlm_ranks' 
ORDER BY ordinal_position;

-- 📊 システム関数確認
SELECT 
    '⚙️ システム関数確認' as info,
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%daily%' OR routine_name LIKE '%weekly%' OR routine_name LIKE '%backup%'
ORDER BY routine_name;

-- 📈 現在のデータ状況確認
SELECT '📊 データ状況確認' as info;

-- アクティブユーザー数
SELECT 
    '👥 アクティブユーザー' as metric,
    COUNT(*) as count
FROM users 
WHERE is_active = true;

-- アクティブNFT数
SELECT 
    '🎨 アクティブNFT' as metric,
    COUNT(*) as count
FROM nfts 
WHERE is_active = true;

-- アクティブなuser_nfts数
SELECT 
    '💎 アクティブuser_nfts' as metric,
    COUNT(*) as count
FROM user_nfts 
WHERE is_active = true AND current_investment > 0;

-- 今日の日利計算結果
SELECT 
    '💰 今日の日利計算' as metric,
    COUNT(*) as calculations,
    COALESCE(SUM(reward_amount), 0) as total_rewards
FROM daily_rewards 
WHERE reward_date = CURRENT_DATE;

-- 今週の週利設定
SELECT 
    '📈 今週の週利設定' as metric,
    COUNT(*) as count
FROM group_weekly_rates 
WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day';

-- 🔧 問題診断
SELECT '🔍 問題診断' as info;

-- 週利設定がないグループ
SELECT 
    '⚠️ 週利未設定グループ' as issue,
    drg.group_name,
    drg.daily_rate_limit
FROM daily_rate_groups drg
LEFT JOIN group_weekly_rates gwr ON drg.id = gwr.group_id 
    AND gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day'
WHERE gwr.id IS NULL;

-- NFTの日利上限設定確認
SELECT 
    '🎯 NFT日利上限確認' as check_type,
    n.name,
    n.daily_rate_limit,
    drg.group_name
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
WHERE n.is_active = true
ORDER BY n.daily_rate_limit;
