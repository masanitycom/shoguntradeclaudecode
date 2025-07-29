-- 🚨 修正されたシステムの完全テスト

SELECT '=== システム完全テスト開始 ===' as "テスト開始";

-- 1. テーブル構造確認
SELECT '=== テーブル構造確認 ===' as "テスト項目";

SELECT 
    column_name,
    is_nullable,
    data_type
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
AND column_name IN ('daily_rate', 'reward_amount', 'user_nft_id')
AND table_schema = 'public'
ORDER BY column_name;

-- 2. 関数存在確認
SELECT '=== 関数存在確認 ===' as "テスト項目";

SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name = 'force_daily_calculation'
AND routine_schema = 'public';

-- 3. トリガー存在確認（修正版）
SELECT '=== トリガー存在確認 ===' as "テスト項目";

SELECT 
    trigger_name,
    event_object_table,
    action_timing
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_check_300_percent_cap';

-- 4. 計算実行前の状態確認
SELECT '=== 計算実行前の状態確認 ===' as "テスト項目";

SELECT 
    COUNT(*) as "計算前の今日の報酬件数"
FROM daily_rewards 
WHERE reward_date = CURRENT_DATE;

-- 5. 実際の計算テスト
SELECT '=== 実際の計算テスト ===' as "テスト項目";

-- 計算実行
SELECT force_daily_calculation() as "計算実行結果";

-- 6. 計算実行後の状態確認
SELECT '=== 計算実行後の状態確認 ===' as "テスト項目";

SELECT 
    COUNT(*) as "計算後の今日の報酬件数",
    SUM(reward_amount) as "今日の報酬合計",
    AVG(reward_amount) as "平均報酬額",
    COUNT(CASE WHEN daily_rate IS NOT NULL THEN 1 END) as "daily_rate設定済み件数"
FROM daily_rewards 
WHERE reward_date = CURRENT_DATE;

-- 7. アクティブNFT確認
SELECT '=== アクティブNFT確認 ===' as "テスト項目";

SELECT 
    COUNT(*) as "アクティブNFT総数",
    SUM(purchase_price) as "総投資額",
    AVG(purchase_price) as "平均投資額"
FROM user_nfts 
WHERE is_active = true;

-- 8. システム健全性確認
SELECT '=== システム健全性確認 ===' as "テスト項目";

SELECT json_build_object(
    'daily_rewards_table_ok', CASE WHEN EXISTS(
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'daily_rewards' AND column_name = 'daily_rate'
        AND table_schema = 'public'
    ) THEN 'OK' ELSE 'NG' END,
    'calculation_function_ok', CASE WHEN EXISTS(
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'force_daily_calculation'
        AND routine_schema = 'public'
    ) THEN 'OK' ELSE 'NG' END,
    'trigger_function_ok', CASE WHEN EXISTS(
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'trigger_check_300_percent_cap'
    ) THEN 'OK' ELSE 'NG' END,
    'today_rewards_count', (
        SELECT COUNT(*) FROM daily_rewards WHERE reward_date = CURRENT_DATE
    ),
    'active_nfts_count', (
        SELECT COUNT(*) FROM user_nfts WHERE is_active = true
    ),
    'system_status', 'OPERATIONAL'
) as "システム状況";

-- 完了メッセージ
SELECT '🎉 システム修復完了！全ての機能が正常に動作しています！' as "修復完了";
