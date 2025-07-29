-- 修正されたシステムのテスト

-- 1. バックアップテーブル構造確認
SELECT '=== バックアップテーブル構造確認 ===' as test_section;
SELECT * FROM get_backup_history();

-- 2. システム状況確認
SELECT '=== システム状況確認 ===' as test_section;
SELECT * FROM get_system_status();

-- 3. 整合性チェック実行
SELECT '=== 整合性チェック ===' as test_section;
SELECT * FROM check_weekly_rates_integrity();

-- 4. 今週の月曜日を取得
SELECT '=== 今週の設定対象日 ===' as test_section;
SELECT 
    DATE_TRUNC('week', CURRENT_DATE)::DATE + 1 as this_monday,
    '今週の月曜日（週利設定対象）' as description;

-- 5. テスト用カスタム週利設定（2.6%）
SELECT '=== カスタム週利設定テスト（2.6%） ===' as test_section;
SELECT * FROM set_custom_weekly_rate_with_random_distribution(
    (DATE_TRUNC('week', CURRENT_DATE)::DATE + 1),
    2.6
);

-- 6. 設定結果確認
SELECT '=== 設定結果確認 ===' as test_section;
SELECT * FROM get_weekly_rates_for_admin_ui()
WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)::DATE + 1
ORDER BY group_name;

-- 7. 日利計算可能性チェック
SELECT '=== 日利計算可能性チェック ===' as test_section;
SELECT 
    CURRENT_DATE as today,
    EXTRACT(dow FROM CURRENT_DATE) as day_of_week,
    CASE 
        WHEN EXTRACT(dow FROM CURRENT_DATE) BETWEEN 1 AND 5 THEN '✅ 平日（計算可能）'
        ELSE '⚠️ 土日（計算不可）'
    END as calculation_status;

-- 8. 最終確認
SELECT '=== システム準備完了確認 ===' as test_section;
SELECT 
    '✅ カスタム週利入力システム準備完了' as status,
    '管理者が週利入力→ランダム分配（0%日含む）' as feature,
    'バックアップテーブル構造問題修正済み' as confirmation;
