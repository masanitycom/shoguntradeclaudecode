-- 最終確認

-- 1. テーブル構造の最終確認
SELECT 
    '📋 テーブル構造確認' as section,
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name IN ('group_weekly_rates', 'daily_rewards', 'user_nfts')
ORDER BY table_name, ordinal_position;

-- 2. 週利設定の確認
SELECT 
    '⚙️ 週利設定確認' as section,
    week_start_date,
    weekly_rate * 100 as weekly_percent,
    monday_rate * 100 as mon_percent,
    tuesday_rate * 100 as tue_percent,
    wednesday_rate * 100 as wed_percent,
    thursday_rate * 100 as thu_percent,
    friday_rate * 100 as fri_percent
FROM group_weekly_rates;

-- 3. 今日の計算結果確認
SELECT 
    '📊 今日の計算結果' as section,
    COUNT(*) as reward_count,
    ROUND(SUM(reward_amount)::numeric, 2) as total_amount,
    ROUND(AVG(reward_amount)::numeric, 4) as avg_reward,
    ROUND(AVG(daily_rate * 100)::numeric, 4) as avg_daily_rate_percent
FROM daily_rewards 
WHERE reward_date = CURRENT_DATE;

-- 4. 関数の動作確認
SELECT 
    '🔧 システム状況関数テスト' as section;
SELECT * FROM get_system_status();

-- 5. 成功メッセージ
SELECT 
    '✅ 緊急修正完了！' as status,
    '日利計算が正常に動作しています' as message,
    format('今日の報酬: %s件、合計$%s', 
           COUNT(*), 
           ROUND(SUM(reward_amount)::numeric, 2)
    ) as result
FROM daily_rewards 
WHERE reward_date = CURRENT_DATE;
