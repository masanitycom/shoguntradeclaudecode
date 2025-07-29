-- 緊急：偽のデータを削除して実際の日付で復元

-- 1. 現在の偽のデータを全削除
DELETE FROM group_weekly_rates;

-- 2. 実際の日付で週利設定を復元
-- 今週（2025年1月6日週）から過去4週間分を正しい日付で作成
DO $$
DECLARE
    current_monday DATE;
    week_date DATE;
    group_rec RECORD;
    week_counter INTEGER := 0;
BEGIN
    -- 今週の月曜日を取得（2025年1月6日）
    current_monday := DATE_TRUNC('week', CURRENT_DATE)::DATE + INTERVAL '1 day';
    
    RAISE NOTICE '今週の月曜日: %', current_monday;
    
    -- 今週から過去4週間分をループ
    FOR i IN 0..4 LOOP
        week_date := current_monday - (i || ' weeks')::INTERVAL;
        week_counter := week_counter + 1;
        
        RAISE NOTICE '週利設定を作成中: % (第%週)', week_date, week_counter;
        
        -- 各グループに週利設定を作成
        FOR group_rec IN SELECT id, group_name FROM daily_rate_groups ORDER BY daily_rate_limit LOOP
            INSERT INTO group_weekly_rates (
                group_id,
                week_start_date,
                weekly_rate,
                monday_rate,
                tuesday_rate,
                wednesday_rate,
                thursday_rate,
                friday_rate,
                created_at,
                updated_at
            ) VALUES (
                group_rec.id,
                week_date,
                0.026, -- 2.6%（デフォルト値）
                0.0052, -- 月曜 0.52%
                0.0052, -- 火曜 0.52%
                0.0052, -- 水曜 0.52%
                0.0052, -- 木曜 0.52%
                0.0052, -- 金曜 0.52%
                NOW(),
                NOW()
            );
            
            RAISE NOTICE '  - %に週利2.6%%を設定', group_rec.group_name;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE '週利設定復元完了: %週間分', week_counter;
END $$;

-- 3. 復元結果確認
SELECT 
    '✅ 正しい日付での復元結果' as section,
    week_start_date,
    (week_start_date + INTERVAL '6 days')::DATE as week_end_date,
    COUNT(*) as group_count,
    AVG(weekly_rate * 100) as avg_weekly_rate
FROM group_weekly_rates
GROUP BY week_start_date
ORDER BY week_start_date DESC;

-- 4. 詳細確認
SELECT 
    '📊 復元された週利設定詳細' as section,
    gwr.week_start_date,
    drg.group_name,
    (gwr.weekly_rate * 100) as weekly_percent,
    (gwr.monday_rate * 100) as mon,
    (gwr.tuesday_rate * 100) as tue,
    (gwr.wednesday_rate * 100) as wed,
    (gwr.thursday_rate * 100) as thu,
    (gwr.friday_rate * 100) as fri
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit;
