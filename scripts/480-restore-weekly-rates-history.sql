-- 週利設定履歴の復元

-- 1. 現在の週利設定データ状況を確認
SELECT 
    '🔍 現在の週利設定データ状況' as section,
    COUNT(*) as total_records,
    COUNT(DISTINCT week_start_date) as unique_weeks,
    MIN(week_start_date) as earliest_week,
    MAX(week_start_date) as latest_week
FROM group_weekly_rates;

-- 2. 詳細な週利設定履歴を確認
SELECT 
    '📅 詳細週利設定履歴' as section,
    week_start_date,
    COUNT(*) as settings_count,
    STRING_AGG(DISTINCT (weekly_rate * 100)::TEXT || '%', ', ') as weekly_rates
FROM group_weekly_rates
GROUP BY week_start_date
ORDER BY week_start_date DESC;

-- 3. 管理画面で表示されるべき週利履歴データを確認
SELECT 
    '📊 管理画面表示用週利履歴' as section,
    gwr.id,
    gwr.week_start_date,
    (gwr.week_start_date + INTERVAL '6 days')::DATE as week_end_date,
    drg.group_name,
    (gwr.weekly_rate * 100) as weekly_rate_percent,
    (gwr.monday_rate * 100) as monday_percent,
    (gwr.tuesday_rate * 100) as tuesday_percent,
    (gwr.wednesday_rate * 100) as wednesday_percent,
    (gwr.thursday_rate * 100) as thursday_percent,
    (gwr.friday_rate * 100) as friday_percent,
    gwr.created_at
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit;

-- 4. 過去の週利設定を復元（もし消えている場合）
-- 過去4週間分の週利設定を作成
DO $$
DECLARE
    week_date DATE;
    group_rec RECORD;
BEGIN
    -- 過去4週間分をループ
    FOR i IN 1..4 LOOP
        week_date := (DATE_TRUNC('week', CURRENT_DATE) - (i || ' weeks')::INTERVAL)::DATE;
        
        -- その週の設定が存在しない場合のみ作成
        IF NOT EXISTS (SELECT 1 FROM group_weekly_rates WHERE week_start_date = week_date) THEN
            RAISE NOTICE '週利設定を復元中: %', week_date;
            
            -- 各グループに週利設定を作成
            FOR group_rec IN SELECT id FROM daily_rate_groups LOOP
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
                    0.026, -- 2.6%
                    0.0052, -- 0.52%
                    0.0052, -- 0.52%
                    0.0052, -- 0.52%
                    0.0052, -- 0.52%
                    0.0052, -- 0.52%
                    week_date + INTERVAL '1 day', -- 作成日時を週の火曜日に設定
                    week_date + INTERVAL '1 day'
                );
            END LOOP;
        ELSE
            RAISE NOTICE '週利設定は既に存在: %', week_date;
        END IF;
    END LOOP;
END $$;

-- 5. 復元後の状況確認
SELECT 
    '✅ 復元後の週利設定状況' as section,
    COUNT(*) as total_records,
    COUNT(DISTINCT week_start_date) as unique_weeks,
    MIN(week_start_date) as earliest_week,
    MAX(week_start_date) as latest_week
FROM group_weekly_rates;

-- 6. 管理画面表示用の最終確認
SELECT 
    '🖥️ 管理画面表示確認' as section,
    week_start_date,
    (week_start_date + INTERVAL '6 days')::DATE as week_end_date,
    COUNT(*) as group_settings,
    AVG(weekly_rate * 100) as avg_weekly_rate
FROM group_weekly_rates
GROUP BY week_start_date
ORDER BY week_start_date DESC;
