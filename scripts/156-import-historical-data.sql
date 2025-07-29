-- CSVデータをインポートして過去の計算を実行

-- 1. 週利データをインポート
SELECT * FROM import_csv_weekly_rates();

-- 2. 過去の日利計算を実行
SELECT * FROM calculate_historical_daily_rewards(10, 18);

-- 3. 結果確認
SELECT 
    week_number,
    COUNT(*) as rate_settings,
    AVG(weekly_rate) as avg_weekly_rate,
    MIN(weekly_rate) as min_rate,
    MAX(weekly_rate) as max_rate
FROM group_weekly_rates
GROUP BY week_number
ORDER BY week_number;

-- 4. 日利報酬の統計
SELECT 
    DATE_PART('week', reward_date) as week_number,
    COUNT(*) as total_rewards,
    SUM(reward_amount) as total_amount,
    AVG(reward_amount) as avg_reward
FROM daily_rewards
WHERE reward_date >= '2025-03-03' -- 第10週の開始日
GROUP BY DATE_PART('week', reward_date)
ORDER BY week_number;

SELECT 'Historical data import completed' as status;
