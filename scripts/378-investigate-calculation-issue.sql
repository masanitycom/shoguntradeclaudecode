-- 計算問題の詳細調査

-- 1. user_nftsテーブルの実際の構造確認
SELECT 
    '📋 user_nftsテーブル構造' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_nfts' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. nftsテーブルの実際の構造確認
SELECT 
    '📋 nftsテーブル構造' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'nfts' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. daily_rewardsテーブルの実際の構造確認
SELECT 
    '📋 daily_rewardsテーブル構造' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. 2/10週の週利設定確認
SELECT 
    '📊 2/10週の週利設定確認' as info,
    drg.group_name,
    drg.daily_rate_limit as 日利上限パーセント,
    gwr.weekly_rate as 週利設定,
    gwr.monday_rate as 月曜,
    gwr.tuesday_rate as 火曜,
    gwr.wednesday_rate as 水曜,
    gwr.thursday_rate as 木曜,
    gwr.friday_rate as 金曜,
    (COALESCE(gwr.monday_rate, 0) + COALESCE(gwr.tuesday_rate, 0) + COALESCE(gwr.wednesday_rate, 0) + 
     COALESCE(gwr.thursday_rate, 0) + COALESCE(gwr.friday_rate, 0)) as 実際合計,
    gwr.week_start_date
FROM daily_rate_groups drg
LEFT JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
WHERE gwr.week_start_date = '2025-02-10'
ORDER BY drg.daily_rate_limit;

-- 5. 問題のユーザーたちの基本データ確認
SELECT 
    '👥 問題ユーザー基本データ' as info,
    u.user_id,
    u.name as ユーザー名,
    u.email
FROM users u
WHERE u.user_id IN ('OHTAKIYO', 'pigret10', 'momochan', 'kimikimi0204', 'imaima3137', 'pbcshop1', 'zenjizenjisan')
ORDER BY u.user_id;
