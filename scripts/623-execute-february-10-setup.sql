-- 2025年2月10日週の設定実行

-- 1. 事前バックアップ作成
SELECT '📦 事前バックアップ作成' as section;
SELECT * FROM admin_create_backup('2025-02-10', '2/10週設定前の安全バックアップ');

-- 2. グループ別週利設定実行
SELECT '⚙️ グループ別週利設定実行' as section;

-- 0.5%グループ: 1.5%
SELECT * FROM set_group_weekly_rate('2025-02-10', '0.5%グループ', 1.5);

-- 1.0%グループ: 2.0%
SELECT * FROM set_group_weekly_rate('2025-02-10', '1.0%グループ', 2.0);

-- 1.25%グループ: 2.3%
SELECT * FROM set_group_weekly_rate('2025-02-10', '1.25%グループ', 2.3);

-- 1.5%グループ: 2.6%
SELECT * FROM set_group_weekly_rate('2025-02-10', '1.5%グループ', 2.6);

-- 1.75%グループ: 2.9%
SELECT * FROM set_group_weekly_rate('2025-02-10', '1.75%グループ', 2.9);

-- 2.0%グループ: 3.2%
SELECT * FROM set_group_weekly_rate('2025-02-10', '2.0%グループ', 3.2);

-- 3. 設定結果確認
SELECT '✅ 設定結果確認' as section;
SELECT 
    drg.group_name,
    ROUND(gwr.weekly_rate * 100, 2) as weekly_rate_percent,
    ROUND(gwr.monday_rate * 100, 2) as monday_percent,
    ROUND(gwr.tuesday_rate * 100, 2) as tuesday_percent,
    ROUND(gwr.wednesday_rate * 100, 2) as wednesday_percent,
    ROUND(gwr.thursday_rate * 100, 2) as thursday_percent,
    ROUND(gwr.friday_rate * 100, 2) as friday_percent
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = '2025-02-10'
ORDER BY drg.daily_rate_limit;

-- 4. 予想報酬計算（月曜日分）
SELECT '💰 予想報酬計算（2/10月曜日分）' as section;
SELECT 
    COUNT(*) as calculation_count,
    SUM(reward_amount) as total_monday_rewards,
    AVG(reward_amount) as avg_reward_per_nft,
    MIN(reward_amount) as min_reward,
    MAX(reward_amount) as max_reward
FROM calculate_daily_rewards_for_date('2025-02-10');

-- 5. ユーザー別予想報酬トップ5
SELECT '🏆 ユーザー別予想報酬トップ5' as section;
SELECT 
    u.username,
    COUNT(calc.user_nft_id) as nft_count,
    SUM(calc.reward_amount) as total_monday_reward
FROM calculate_daily_rewards_for_date('2025-02-10') calc
JOIN users u ON calc.user_id = u.id
GROUP BY u.id, u.username
ORDER BY total_monday_reward DESC
LIMIT 5;

-- 6. 最終確認
SELECT '🎯 最終確認' as section;
SELECT 
    '2025-02-10週の設定完了' as status,
    COUNT(DISTINCT gwr.group_id) as configured_groups,
    COUNT(*) as total_settings,
    MIN(gwr.weekly_rate * 100) || '% - ' || MAX(gwr.weekly_rate * 100) || '%' as rate_range
FROM group_weekly_rates gwr
WHERE gwr.week_start_date = '2025-02-10';

SELECT 'February 10 setup execution completed successfully!' as status;
