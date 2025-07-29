-- 手動週利設定の使用例とテスト

-- 1. 現在設定済みの週を確認
SELECT 'Currently Configured Weeks' as info;
SELECT * FROM list_configured_weeks();

-- 2. 今週の月曜日を取得
SELECT 
    'Current Week Monday' as info,
    (DATE_TRUNC('week', CURRENT_DATE)::DATE + 1) as current_monday;

-- 3. 使用例：今週の週利を2.6%に設定
-- SELECT * FROM set_weekly_rate_manual('2024-12-30', 2.6, 'random');

-- 4. 使用例：特定の週の設定を確認
-- SELECT * FROM check_weekly_rate('2024-12-30');

-- 5. 使用例：週利設定を削除
-- SELECT * FROM delete_weekly_rate('2024-12-30');

-- 6. 手動設定のためのヘルパー情報
SELECT 
    'Helper Info' as category,
    'Manual Weekly Rate Setting Guide' as info;

SELECT 
    'Step 1' as step,
    'Use set_weekly_rate_manual(date, rate, method)' as instruction,
    'Example: SELECT * FROM set_weekly_rate_manual(''2024-12-30'', 2.6, ''random'');' as example;

SELECT 
    'Step 2' as step,
    'Check the result with check_weekly_rate(date)' as instruction,
    'Example: SELECT * FROM check_weekly_rate(''2024-12-30'');' as example;

SELECT 
    'Step 3' as step,
    'View all configured weeks with list_configured_weeks()' as instruction,
    'Example: SELECT * FROM list_configured_weeks();' as example;

-- 7. 今後の週の日付を表示（手動設定の参考用）
SELECT 
    'Future Mondays for Manual Setting' as info,
    generate_series(
        DATE_TRUNC('week', CURRENT_DATE)::DATE + 1,
        DATE_TRUNC('week', CURRENT_DATE + INTERVAL '8 weeks')::DATE + 1,
        '7 days'::INTERVAL
    )::DATE as monday_dates;
