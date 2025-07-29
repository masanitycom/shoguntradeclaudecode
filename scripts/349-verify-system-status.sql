-- システム状態の確認

-- 1. テーブル存在確認
SELECT 
    '📊 テーブル存在確認' as status,
    table_name,
    CASE 
        WHEN table_name IS NOT NULL THEN '存在'
        ELSE '不存在'
    END as table_status
FROM information_schema.tables 
WHERE table_name IN ('group_weekly_rates', 'daily_rate_groups', 'nfts', 'user_nfts', 'daily_rewards')
ORDER BY table_name;

-- 2. 外部キー制約確認
SELECT 
    '🔗 外部キー制約確認' as check_type,
    tc.table_name,
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_name IN ('group_weekly_rates', 'daily_rewards', 'user_nfts');

-- 3. データ件数確認
SELECT 
    '📊 データ件数確認' as check_type,
    'users' as table_name,
    COUNT(*) as record_count
FROM users
UNION ALL
SELECT 
    '📊 データ件数確認',
    'nfts',
    COUNT(*)
FROM nfts
UNION ALL
SELECT 
    '📊 データ件数確認',
    'user_nfts',
    COUNT(*)
FROM user_nfts
UNION ALL
SELECT 
    '📊 データ件数確認',
    'daily_rate_groups',
    COUNT(*)
FROM daily_rate_groups
UNION ALL
SELECT 
    '📊 データ件数確認',
    'group_weekly_rates',
    COUNT(*)
FROM group_weekly_rates
UNION ALL
SELECT 
    '📊 データ件数確認',
    'daily_rewards',
    COUNT(*)
FROM daily_rewards;

-- 4. daily_rate_groupsデータ確認
SELECT 
    '📊 daily_rate_groupsデータ確認' as status,
    group_name,
    daily_rate_limit,
    description
FROM daily_rate_groups
ORDER BY group_name;

-- 5. group_weekly_ratesとの関係確認
SELECT 
    '📊 テーブル関係確認' as status,
    gwr.nft_group,
    drg.group_name,
    drg.daily_rate_limit,
    gwr.weekly_rate,
    CASE 
        WHEN gwr.group_id IS NOT NULL THEN '関係あり'
        ELSE '関係なし'
    END as relationship_status
FROM group_weekly_rates gwr
LEFT JOIN daily_rate_groups drg ON gwr.group_id = drg.id
ORDER BY gwr.nft_group;

-- 6. NFTグループ分類確認
SELECT 
    '📊 NFTグループ分類確認' as status,
    n.name,
    n.price,
    CASE 
        WHEN n.price <= 125 THEN 'group_125'
        WHEN n.price <= 250 THEN 'group_250'
        WHEN n.price <= 375 THEN 'group_375'
        WHEN n.price <= 625 THEN 'group_625'
        WHEN n.price <= 1250 THEN 'group_1250'
        WHEN n.price <= 2500 THEN 'group_2500'
        WHEN n.price <= 7500 THEN 'group_7500'
        ELSE 'group_high'
    END as nft_group,
    n.daily_rate_limit
FROM nfts n
ORDER BY n.price;

-- 7. ユーザーNFT保有状況確認
SELECT 
    '📊 ユーザーNFT保有状況' as status,
    COUNT(*) as total_user_nfts,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_nfts,
    SUM(current_investment) as total_investment,
    AVG(current_investment) as avg_investment
FROM user_nfts;

-- 8. 日利報酬データ確認
SELECT 
    '📊 日利報酬データ確認' as status,
    COUNT(*) as total_rewards,
    COUNT(CASE WHEN is_claimed = true THEN 1 END) as claimed_rewards,
    SUM(reward_amount) as total_reward_amount,
    MAX(reward_date) as latest_reward_date
FROM daily_rewards;

-- 9. 週利設定状況確認
SELECT 
    '📅 今週の週利設定状況' as check_type,
    gwr.nft_group,
    drg.group_name,
    gwr.weekly_rate,
    gwr.monday_rate,
    gwr.tuesday_rate,
    gwr.wednesday_rate,
    gwr.thursday_rate,
    gwr.friday_rate
FROM group_weekly_rates gwr
LEFT JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)
ORDER BY drg.group_name;

-- 10. 関数存在確認
SELECT 
    '⚙️ 関数存在確認' as check_type,
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN (
    'get_nft_group',
    'is_weekday',
    'check_300_percent_cap',
    'calculate_daily_rewards'
)
ORDER BY routine_name;

-- 11. テーブル構造確認
SELECT 
    '📋 daily_rate_groups構造確認' as status,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'daily_rate_groups'
ORDER BY ordinal_position;

-- 12. group_weekly_rates構造確認
SELECT 
    '📋 group_weekly_rates構造確認' as status,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'group_weekly_rates'
ORDER BY ordinal_position;
