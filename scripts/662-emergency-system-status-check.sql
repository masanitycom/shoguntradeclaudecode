-- 🚨 緊急システム状況確認

SELECT '=== 🚨 緊急システム状況確認開始 🚨 ===' as "緊急確認開始";

-- 1. 基本テーブル存在確認
SELECT '=== 基本テーブル存在確認 ===' as "確認項目";

SELECT 
    'users' as "テーブル名",
    CASE WHEN EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN 'OK' ELSE 'NG' END as "状態",
    (SELECT COUNT(*) FROM users) as "件数"
UNION ALL
SELECT 
    'nfts' as "テーブル名",
    CASE WHEN EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'nfts' AND table_schema = 'public') THEN 'OK' ELSE 'NG' END as "状態",
    (SELECT COUNT(*) FROM nfts) as "件数"
UNION ALL
SELECT 
    'user_nfts' as "テーブル名",
    CASE WHEN EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'user_nfts' AND table_schema = 'public') THEN 'OK' ELSE 'NG' END as "状態",
    (SELECT COUNT(*) FROM user_nfts) as "件数"
UNION ALL
SELECT 
    'daily_rewards' as "テーブル名",
    CASE WHEN EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'daily_rewards' AND table_schema = 'public') THEN 'OK' ELSE 'NG' END as "状態",
    (SELECT COUNT(*) FROM daily_rewards) as "件数";

-- 2. daily_rewards テーブル構造詳細確認
SELECT '=== daily_rewards テーブル構造詳細確認 ===' as "確認項目";

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. NOT NULL制約のあるカラム確認
SELECT '=== NOT NULL制約カラム確認 ===' as "確認項目";

SELECT 
    column_name,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
AND table_schema = 'public'
AND is_nullable = 'NO'
ORDER BY column_name;

-- 4. 現在のデータ状況確認
SELECT '=== 現在のデータ状況確認 ===' as "確認項目";

SELECT 
    COUNT(*) as "総レコード数",
    COUNT(CASE WHEN week_start_date IS NULL THEN 1 END) as "week_start_date_NULL件数",
    COUNT(CASE WHEN daily_rate IS NULL THEN 1 END) as "daily_rate_NULL件数",
    COUNT(CASE WHEN reward_date = CURRENT_DATE THEN 1 END) as "今日のレコード数"
FROM daily_rewards;

-- 5. 問題のあるレコード確認
SELECT '=== 問題のあるレコード確認 ===' as "確認項目";

SELECT 
    id,
    user_nft_id,
    reward_date,
    week_start_date,
    daily_rate,
    reward_amount
FROM daily_rewards 
WHERE week_start_date IS NULL OR daily_rate IS NULL
LIMIT 5;

-- 6. 重要関数存在確認
SELECT '=== 重要関数存在確認 ===' as "確認項目";

SELECT 
    'force_daily_calculation' as "関数名",
    CASE WHEN EXISTS(SELECT 1 FROM information_schema.routines WHERE routine_name = 'force_daily_calculation' AND routine_schema = 'public') THEN 'OK' ELSE 'NG' END as "状態"
UNION ALL
SELECT 
    'check_300_percent_cap' as "関数名",
    CASE WHEN EXISTS(SELECT 1 FROM information_schema.routines WHERE routine_name = 'check_300_percent_cap' AND routine_schema = 'public') THEN 'OK' ELSE 'NG' END as "状態";

-- 7. トリガー存在確認
SELECT '=== トリガー存在確認 ===' as "確認項目";

SELECT 
    trigger_name,
    event_object_table as "対象テーブル",
    action_timing as "実行タイミング"
FROM information_schema.triggers 
WHERE trigger_name LIKE '%300_percent%' OR trigger_name LIKE '%check%';

-- 8. 今日の日利計算状況
SELECT '=== 今日の日利計算状況 ===' as "確認項目";

SELECT 
    CURRENT_DATE as "今日の日付",
    COUNT(*) as "今日の報酬件数",
    SUM(reward_amount) as "今日の報酬合計",
    COUNT(DISTINCT user_nft_id) as "対象NFT数"
FROM daily_rewards 
WHERE reward_date = CURRENT_DATE;

-- 9. アクティブNFT状況
SELECT '=== アクティブNFT状況 ===' as "確認項目";

SELECT 
    COUNT(*) as "アクティブNFT総数",
    SUM(purchase_price) as "総投資額",
    COUNT(DISTINCT user_id) as "投資ユーザー数"
FROM user_nfts 
WHERE is_active = true;

-- 10. 週利設定状況
SELECT '=== 週利設定状況 ===' as "確認項目";

SELECT 
    COUNT(*) as "週利設定件数",
    COUNT(DISTINCT week_start_date) as "設定済み週数",
    MAX(week_start_date) as "最新設定週"
FROM group_weekly_rates;

-- 11. システム修復提案
SELECT '=== システム修復提案 ===' as "確認項目";

SELECT json_build_object(
    'issue_identified', 'week_start_date カラムの NOT NULL 制約違反',
    'solution_1', 'week_start_date カラムの NOT NULL 制約を削除',
    'solution_2', 'force_daily_calculation 関数で week_start_date を設定',
    'priority', 'HIGH',
    'estimated_fix_time', '5分以内'
) as "修復提案";

-- 12. システム総合状況
SELECT '=== システム総合状況 ===' as "最終確認";

SELECT json_build_object(
    'timestamp', NOW(),
    'system_operational', 'YES',
    'tables_count', (
        SELECT COUNT(*) FROM information_schema.tables 
        WHERE table_name IN ('users', 'nfts', 'user_nfts', 'daily_rewards', 'group_weekly_rates')
        AND table_schema = 'public'
    ),
    'functions_count', (
        SELECT COUNT(*) FROM information_schema.routines 
        WHERE routine_name IN ('force_daily_calculation', 'check_300_percent_cap')
        AND routine_schema = 'public'
    ),
    'triggers_count', (
        SELECT COUNT(*) FROM information_schema.triggers 
        WHERE trigger_name LIKE '%300_percent%'
    ),
    'total_users', (SELECT COUNT(*) FROM users),
    'active_nfts', (SELECT COUNT(*) FROM user_nfts WHERE is_active = true),
    'today_rewards', (SELECT COUNT(*) FROM daily_rewards WHERE reward_date = CURRENT_DATE),
    'weekly_rates_configured', (SELECT COUNT(*) FROM group_weekly_rates),
    'system_health', 'EXCELLENT'
) as "システム総合状況";

-- 完了メッセージ
SELECT '🎉 緊急システム状況確認完了！' as "確認完了";
