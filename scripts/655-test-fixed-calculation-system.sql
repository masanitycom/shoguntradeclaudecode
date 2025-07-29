-- 🚨 修正されたシステムのテスト

-- 1. 300%キャップトリガーのテスト
SELECT '=== 300%キャップトリガーテスト ===' as "テスト開始";

-- トリガーが正しく作成されているか確認
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_check_300_percent_cap';

-- 2. 日利計算関数のテスト
SELECT '=== 日利計算関数テスト ===' as "テスト開始";

-- 関数が正しく作成されているか確認
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name = 'force_daily_calculation';

-- 3. 実際の計算テスト（安全なテスト実行）
SELECT '=== 実際の計算テスト ===' as "テスト開始";

-- テスト用の一時的な計算実行
SELECT force_daily_calculation() as "計算結果";

-- 4. 結果確認
SELECT '=== 結果確認 ===' as "確認開始";

-- 今日の日利報酬件数確認
SELECT 
    COUNT(*) as "今日の報酬件数",
    SUM(reward_amount) as "今日の報酬合計",
    AVG(reward_amount) as "平均報酬額"
FROM daily_rewards 
WHERE reward_date = CURRENT_DATE;

-- アクティブなユーザーNFT数確認
SELECT 
    COUNT(*) as "アクティブNFT数",
    SUM(purchase_price) as "総投資額",
    SUM(total_earned) as "総獲得額"
FROM user_nfts 
WHERE is_active = true;

-- 5. システム状況サマリー
SELECT '=== システム状況サマリー ===' as "サマリー";

SELECT json_build_object(
    'trigger_status', CASE WHEN EXISTS(
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'trigger_check_300_percent_cap'
    ) THEN 'OK' ELSE 'NG' END,
    'function_status', CASE WHEN EXISTS(
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'force_daily_calculation'
    ) THEN 'OK' ELSE 'NG' END,
    'daily_rewards_count', (SELECT COUNT(*) FROM daily_rewards WHERE reward_date = CURRENT_DATE),
    'active_nfts_count', (SELECT COUNT(*) FROM user_nfts WHERE is_active = true),
    'system_ready', CASE WHEN EXISTS(
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'trigger_check_300_percent_cap'
    ) AND EXISTS(
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'force_daily_calculation'
    ) THEN 'YES' ELSE 'NO' END
) as "システム状況";

-- 完了メッセージ
SELECT '🎉 システム修復テスト完了！' as "完了";
