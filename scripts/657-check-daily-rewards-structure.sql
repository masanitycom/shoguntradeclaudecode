-- 🚨 daily_rewards テーブルの構造を確認

SELECT '=== daily_rewards テーブル構造確認 ===' as "確認開始";

-- テーブル構造を詳細に確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 制約を確認（テーブル名を明示）
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    ccu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_name = 'daily_rewards'
AND tc.table_schema = 'public';

-- サンプルデータを確認
SELECT 
    COUNT(*) as "総レコード数",
    COUNT(daily_rate) as "daily_rate非NULL数",
    COUNT(reward_amount) as "reward_amount非NULL数"
FROM daily_rewards;

SELECT '=== 構造確認完了 ===' as "確認完了";
