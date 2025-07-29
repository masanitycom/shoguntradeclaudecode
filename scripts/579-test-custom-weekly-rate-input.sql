-- カスタム週利入力システムのテスト

-- 1. 今週の月曜日を取得
DO $$
DECLARE
    test_week_start DATE;
    test_result RECORD;
BEGIN
    -- 今週の月曜日を計算
    test_week_start := DATE_TRUNC('week', CURRENT_DATE)::DATE + 1;
    
    RAISE NOTICE '=== カスタム週利入力システムテスト ===';
    RAISE NOTICE '対象週: %', test_week_start;
    
    -- 2.6%の週利をテスト
    RAISE NOTICE '週利2.6%%をランダム分配でテスト中...';
    
    FOR test_result IN
        SELECT * FROM set_custom_weekly_rate_with_random_distribution(test_week_start, 2.6)
    LOOP
        RAISE NOTICE 'グループ: %, 週利: %%, 月: %%, 火: %%, 水: %%, 木: %%, 金: %%, 結果: %',
            test_result.group_name,
            (test_result.weekly_rate_set * 100)::NUMERIC(5,2),
            (test_result.monday_rate * 100)::NUMERIC(5,2),
            (test_result.tuesday_rate * 100)::NUMERIC(5,2),
            (test_result.wednesday_rate * 100)::NUMERIC(5,2),
            (test_result.thursday_rate * 100)::NUMERIC(5,2),
            (test_result.friday_rate * 100)::NUMERIC(5,2),
            test_result.message;
    END LOOP;
    
    RAISE NOTICE '=== テスト完了 ===';
END $$;

-- 設定結果を確認
SELECT 
    drg.group_name,
    gwr.week_start_date,
    (gwr.weekly_rate * 100)::NUMERIC(5,2) as weekly_rate_percent,
    (gwr.monday_rate * 100)::NUMERIC(5,2) as monday_percent,
    (gwr.tuesday_rate * 100)::NUMERIC(5,2) as tuesday_percent,
    (gwr.wednesday_rate * 100)::NUMERIC(5,2) as wednesday_percent,
    (gwr.thursday_rate * 100)::NUMERIC(5,2) as thursday_percent,
    (gwr.friday_rate * 100)::NUMERIC(5,2) as friday_percent,
    gwr.distribution_method
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)::DATE + 1
ORDER BY drg.daily_rate_limit;
