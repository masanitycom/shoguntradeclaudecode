-- 緊急調査: 報酬残存問題とテーブル構造確認

-- 1. usersテーブルの構造確認
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

-- 2. daily_rewardsテーブルの構造確認
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
ORDER BY ordinal_position;

-- 3. 現在の報酬データ確認
SELECT 
    COUNT(*) as total_rewards,
    SUM(reward_amount) as total_amount,
    MIN(created_at) as earliest_reward,
    MAX(created_at) as latest_reward
FROM daily_rewards;

-- 4. group_weekly_ratesテーブルの状況確認
SELECT 
    COUNT(*) as total_weekly_rates,
    MIN(week_start_date) as earliest_week,
    MAX(week_start_date) as latest_week
FROM group_weekly_rates;

-- 5. ユーザー別報酬集計（正しいカラム名を使用）
SELECT 
    u.name,
    u.email,
    COUNT(dr.id) as reward_count,
    COALESCE(SUM(dr.reward_amount), 0) as total_rewards
FROM users u
LEFT JOIN daily_rewards dr ON u.id = dr.user_id
GROUP BY u.id, u.name, u.email
HAVING COUNT(dr.id) > 0
ORDER BY total_rewards DESC
LIMIT 20;

-- 6. 最新の日利計算関数確認
SELECT 
    proname as function_name,
    prosrc as function_body
FROM pg_proc 
WHERE proname LIKE '%daily_calculation%' 
   OR proname LIKE '%force_daily%';
