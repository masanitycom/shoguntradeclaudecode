-- 🚨 緊急システム調査 - なぜ週利設定なしで利益が発生しているか

-- 1. 現在の週利設定状況を確認
SELECT 
    '📊 現在の週利設定状況' as section,
    COUNT(*) as total_weekly_rates,
    COUNT(DISTINCT week_start_date) as weeks_with_settings,
    MIN(week_start_date) as earliest_week,
    MAX(week_start_date) as latest_week,
    STRING_AGG(DISTINCT week_start_date::TEXT, ', ' ORDER BY week_start_date::TEXT) as all_weeks
FROM group_weekly_rates;

-- 2. daily_rewards テーブルの状況確認
SELECT 
    '🔍 日利報酬データ確認' as section,
    COUNT(*) as total_daily_rewards,
    COUNT(DISTINCT reward_date) as days_with_rewards,
    COUNT(DISTINCT user_id) as users_with_rewards,
    SUM(reward_amount) as total_reward_amount,
    MIN(reward_date) as earliest_reward_date,
    MAX(reward_date) as latest_reward_date
FROM daily_rewards;

-- 3. 最近の日利報酬詳細（上位10件）
SELECT 
    '📋 最近の日利報酬詳細' as section,
    dr.reward_date,
    u.name as user_name,
    n.name as nft_name,
    dr.reward_amount,
    dr.daily_rate,
    dr.investment_amount,
    dr.week_start_date,
    dr.created_at
FROM daily_rewards dr
JOIN users u ON dr.user_id = u.id
JOIN nfts n ON dr.nft_id = n.id
ORDER BY dr.created_at DESC
LIMIT 10;

-- 4. user_nfts の total_earned 状況
SELECT 
    '💰 ユーザーNFT獲得状況' as section,
    COUNT(*) as total_user_nfts,
    COUNT(*) FILTER (WHERE total_earned > 0) as nfts_with_earnings,
    SUM(total_earned) as total_all_earnings,
    AVG(total_earned) as avg_earnings,
    MAX(total_earned) as max_earnings
FROM user_nfts;

-- 5. 獲得額が多いユーザーNFT（上位5件）
SELECT 
    '🔥 獲得額上位ユーザーNFT' as section,
    u.name as user_name,
    n.name as nft_name,
    un.total_earned,
    un.current_investment,
    un.purchase_date,
    un.is_active
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.total_earned > 0
ORDER BY un.total_earned DESC
LIMIT 5;

-- 6. 計算関数の実行履歴確認
SELECT 
    '⚙️ 計算関数実行状況' as section,
    'daily_rewards テーブルの最新更新' as check_type,
    MAX(created_at) as last_calculation,
    COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE) as today_calculations
FROM daily_rewards;

-- 7. 週利設定と日利報酬の関連性チェック
SELECT 
    '🔗 週利設定と日利報酬の関連性' as section,
    dr.week_start_date,
    COUNT(DISTINCT dr.reward_date) as reward_days,
    SUM(dr.reward_amount) as total_rewards,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM group_weekly_rates gwr 
            WHERE gwr.week_start_date = dr.week_start_date
        ) THEN '週利設定あり'
        ELSE '⚠️ 週利設定なし'
    END as weekly_rate_status
FROM daily_rewards dr
GROUP BY dr.week_start_date
ORDER BY dr.week_start_date DESC;

-- 8. システムの整合性チェック
SELECT 
    '🚨 システム整合性チェック' as section,
    CASE 
        WHEN (SELECT COUNT(*) FROM group_weekly_rates) = 0 
             AND (SELECT COUNT(*) FROM daily_rewards WHERE reward_amount > 0) > 0
        THEN '❌ 致命的エラー: 週利設定なしで利益発生'
        WHEN (SELECT COUNT(*) FROM group_weekly_rates) > 0 
             AND (SELECT COUNT(*) FROM daily_rewards WHERE reward_amount > 0) = 0
        THEN '⚠️ 警告: 週利設定ありだが利益なし'
        WHEN (SELECT COUNT(*) FROM group_weekly_rates) > 0 
             AND (SELECT COUNT(*) FROM daily_rewards WHERE reward_amount > 0) > 0
        THEN '✅ 正常: 週利設定と利益が一致'
        ELSE '✅ 正常: 週利設定なし、利益なし'
    END as system_status;
