-- daily_rewardsテーブルの正確な構造を確認

SELECT 
    '📋 daily_rewards テーブル構造' as table_info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- 制約情報
SELECT 
    '🔗 daily_rewards 制約情報' as constraint_info,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'daily_rewards' 
    AND table_schema = 'public';

-- トリガー情報
SELECT 
    '🔧 daily_rewards トリガー情報' as trigger_info,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'daily_rewards' 
    AND event_object_schema = 'public';

-- サンプルデータ（存在する場合）
SELECT 
    '📊 daily_rewards サンプルデータ' as data_info,
    *
FROM daily_rewards 
LIMIT 3;

-- テーブルが空の場合の確認
SELECT 
    '📈 daily_rewards レコード数' as count_info,
    COUNT(*) as total_records,
    COUNT(CASE WHEN reward_date >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as recent_records
FROM daily_rewards;
