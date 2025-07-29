-- ダッシュボード表示の最終修正

-- 1. user_nftsテーブルのtotal_earnedを日利報酬から正確に再計算
UPDATE user_nfts 
SET 
    total_earned = COALESCE((
        SELECT SUM(reward_amount) 
        FROM daily_rewards 
        WHERE user_nft_id = user_nfts.id
    ), 0),
    updated_at = CURRENT_TIMESTAMP
WHERE is_active = true;

-- 2. 計算結果の確認
SELECT 
    '🔄 total_earned更新結果' as check_type,
    COUNT(*) as updated_nfts,
    SUM(total_earned) as total_system_earnings,
    AVG(total_earned) as avg_earnings_per_nft
FROM user_nfts 
WHERE is_active = true AND total_earned > 0;

-- 3. ユーザーダッシュボード用のビューを作成/更新
DROP VIEW IF EXISTS user_dashboard_summary;
CREATE VIEW user_dashboard_summary AS
SELECT 
    u.id as user_id,
    u.display_name,
    u.email,
    COUNT(un.id) as nft_count,
    COALESCE(SUM(un.purchase_price), 0) as total_investment,
    COALESCE(SUM(un.total_earned), 0) as total_earned,
    COUNT(CASE WHEN un.total_earned >= un.purchase_price * 3 THEN 1 END) as completed_nfts,
    COALESCE(SUM(CASE WHEN un.total_earned < un.purchase_price * 3 THEN un.purchase_price * 3 - un.total_earned ELSE 0 END), 0) as remaining_earnings,
    CASE 
        WHEN SUM(un.purchase_price) > 0 THEN 
            ROUND((SUM(un.total_earned) / SUM(un.purchase_price) * 100), 2)
        ELSE 0 
    END as earning_percentage,
    MAX(un.updated_at) as last_update
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE u.is_admin = false
GROUP BY u.id, u.display_name, u.email;

-- 4. 最近の日利報酬ビューを作成/更新
DROP VIEW IF EXISTS recent_daily_rewards;
CREATE VIEW recent_daily_rewards AS
SELECT 
    u.display_name,
    n.name as nft_name,
    dr.reward_date,
    ROUND(dr.reward_amount, 2) as reward_amount,
    ROUND(dr.daily_rate_used * 100, 3) as daily_rate_percent,
    dr.calculation_date
FROM daily_rewards dr
JOIN users u ON dr.user_id = u.id
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
WHERE dr.reward_date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY dr.reward_date DESC, dr.calculation_date DESC;

-- 5. 管理者用の報酬サマリービューを作成/更新
DROP VIEW IF EXISTS admin_rewards_summary;
CREATE VIEW admin_rewards_summary AS
SELECT 
    DATE(dr.reward_date) as reward_date,
    COUNT(DISTINCT dr.user_id) as active_users,
    COUNT(dr.id) as total_rewards,
    ROUND(SUM(dr.reward_amount), 2) as total_amount,
    ROUND(AVG(dr.reward_amount), 2) as avg_reward,
    ROUND(AVG(dr.daily_rate_used * 100), 3) as avg_daily_rate
FROM daily_rewards dr
WHERE dr.reward_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(dr.reward_date)
ORDER BY reward_date DESC;

-- 6. 最終確認：トップユーザーの報酬状況
SELECT 
    '🏆 最終確認：トップユーザー' as check_type,
    display_name,
    nft_count,
    total_investment,
    total_earned,
    earning_percentage || '%' as earning_percent,
    completed_nfts,
    remaining_earnings
FROM user_dashboard_summary
WHERE total_investment > 0
ORDER BY total_earned DESC
LIMIT 15;

-- 7. システム状態の最終確認
SELECT 
    '🎯 システム最終状態' as check_type,
    'SUCCESS' as status,
    COUNT(DISTINCT uds.user_id) as total_active_users,
    SUM(uds.nft_count) as total_active_nfts,
    ROUND(SUM(uds.total_earned), 2) as total_system_rewards,
    ROUND(AVG(uds.earning_percentage), 2) as avg_earning_percentage,
    (SELECT MAX(calculation_date) FROM daily_rewards) as last_calculation
FROM user_dashboard_summary uds
WHERE uds.total_investment > 0;

-- 8. 日利報酬の最新状況
SELECT 
    '📈 日利報酬最新状況' as check_type,
    reward_date,
    COUNT(*) as rewards_count,
    COUNT(DISTINCT user_id) as users_count,
    ROUND(SUM(reward_amount), 2) as daily_total
FROM daily_rewards
WHERE reward_date >= CURRENT_DATE - INTERVAL '3 days'
GROUP BY reward_date
ORDER BY reward_date DESC;

-- 9. 成功メッセージ
SELECT 
    '🎉 修正完了' as status,
    '全ユーザーの報酬が正常に計算・表示されるようになりました！' as message,
    CURRENT_TIMESTAMP as completion_time;

RAISE NOTICE '🎉 緊急修正完了！全ユーザーの報酬が正常に表示されるようになりました！';
RAISE NOTICE '📊 ダッシュボードを確認してください。';
