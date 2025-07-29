-- 🚨 緊急診断と修復

-- 1. システム診断実行
SELECT * FROM emergency_system_diagnosis();

-- 2. 2月10日データ確認
SELECT * FROM check_february_10_data();

-- 3. 必要なグループが存在するか確認
SELECT * FROM daily_rate_groups ORDER BY daily_rate_limit;

-- 4. グループが存在しない場合は作成
INSERT INTO daily_rate_groups (group_name, daily_rate_limit) VALUES
('0.5%グループ', 0.005),
('1.0%グループ', 0.01),
('1.25%グループ', 0.0125),
('1.5%グループ', 0.015),
('1.75%グループ', 0.0175),
('2.0%グループ', 0.02)
ON CONFLICT (group_name) DO NOTHING;

-- 5. 2025年2月10日の週利を強制設定
DO $$
DECLARE
    group_names TEXT[] := ARRAY['0.5%グループ', '1.0%グループ', '1.25%グループ', '1.5%グループ', '1.75%グループ', '2.0%グループ'];
    group_rates NUMERIC[] := ARRAY[1.5, 2.0, 2.3, 2.6, 2.9, 3.2];
    i INTEGER;
    result_record RECORD;
BEGIN
    FOR i IN 1..array_length(group_names, 1) LOOP
        SELECT * INTO result_record FROM set_group_weekly_rate_simple('2025-02-10', group_names[i], group_rates[i]);
        RAISE NOTICE '設定結果: % - %', group_names[i], result_record.message;
    END LOOP;
END $$;

-- 6. 設定確認
SELECT 
    drg.group_name,
    gwr.weekly_rate * 100 as weekly_rate_percent,
    gwr.monday_rate * 100 as monday_percent,
    gwr.tuesday_rate * 100 as tuesday_percent,
    gwr.wednesday_rate * 100 as wednesday_percent,
    gwr.thursday_rate * 100 as thursday_percent,
    gwr.friday_rate * 100 as friday_percent
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = '2025-02-10'
ORDER BY drg.daily_rate_limit;

-- 7. システム状況再確認
SELECT * FROM get_system_status_simple();

-- 8. 週利設定履歴確認
SELECT * FROM get_weekly_rates_simple() LIMIT 10;
