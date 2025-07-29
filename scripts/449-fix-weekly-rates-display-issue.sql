-- 週利設定表示問題の修正

DO $$
DECLARE
    current_monday DATE;
    group_record RECORD;
    created_count INTEGER := 0;
    debug_msg TEXT;
BEGIN
    -- 今週の月曜日を取得
    current_monday := DATE_TRUNC('week', CURRENT_DATE)::DATE + INTERVAL '1 day';
    
    debug_msg := '📅 今週の月曜日: ' || current_monday;
    RAISE NOTICE '%', debug_msg;
    
    -- 既存の今週設定を削除
    DELETE FROM group_weekly_rates WHERE week_start_date = current_monday;
    debug_msg := '🗑️ 既存の今週設定を削除';
    RAISE NOTICE '%', debug_msg;
    
    -- 各グループに週利2.6%を設定
    FOR group_record IN 
        SELECT id, group_name, daily_rate_limit FROM daily_rate_groups ORDER BY daily_rate_limit
    LOOP
        INSERT INTO group_weekly_rates (
            group_id,
            week_start_date,
            week_end_date,
            week_number,
            weekly_rate,
            monday_rate,
            tuesday_rate,
            wednesday_rate,
            thursday_rate,
            friday_rate,
            distribution_method,
            created_at,
            updated_at
        ) VALUES (
            group_record.id,
            current_monday,
            current_monday + INTERVAL '4 days',
            EXTRACT(week FROM current_monday),
            0.026, -- 2.6%
            0.0052, -- 月曜 0.52%
            0.0052, -- 火曜 0.52%
            0.0052, -- 水曜 0.52%
            0.0052, -- 木曜 0.52%
            0.0052, -- 金曜 0.52%
            'manual',
            NOW(),
            NOW()
        );
        
        created_count := created_count + 1;
        debug_msg := '✅ 週利設定作成: ' || group_record.group_name || ' (2.6%)';
        RAISE NOTICE '%', debug_msg;
    END LOOP;
    
    debug_msg := '🎯 週利設定完了: ' || created_count || '件作成';
    RAISE NOTICE '%', debug_msg;
END $$;

-- 週利設定確認
SELECT 
    '📊 週利設定確認' as section,
    COUNT(*) as total_settings,
    COUNT(DISTINCT group_id) as unique_groups,
    MIN(week_start_date) as earliest_week,
    MAX(week_start_date) as latest_week
FROM group_weekly_rates;

-- 今週の設定詳細
SELECT 
    '📅 今週の設定詳細' as section,
    drg.group_name,
    gwr.weekly_rate,
    gwr.monday_rate,
    gwr.tuesday_rate,
    gwr.wednesday_rate,
    gwr.thursday_rate,
    gwr.friday_rate
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)::DATE + INTERVAL '1 day'
ORDER BY drg.daily_rate_limit;
