-- 週利設定を強制的に再作成

DO $$
DECLARE
    current_week_start DATE;
    group_record RECORD;
    insert_count INTEGER := 0;
    debug_msg TEXT;
BEGIN
    debug_msg := '🚨 週利設定強制再作成開始';
    RAISE NOTICE '%', debug_msg;
    
    -- 今週の月曜日を正確に計算
    current_week_start := DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day';
    
    debug_msg := '📅 今週の開始日: ' || current_week_start;
    RAISE NOTICE '%', debug_msg;
    
    -- 全ての週利設定を一旦削除
    DELETE FROM group_weekly_rates;
    debug_msg := '🗑️ 全ての週利設定を削除';
    RAISE NOTICE '%', debug_msg;
    
    -- 各グループに週利設定を強制作成
    FOR group_record IN 
        SELECT id, group_name, daily_rate_limit 
        FROM daily_rate_groups 
        ORDER BY daily_rate_limit
    LOOP
        INSERT INTO group_weekly_rates (
            id,
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
            gen_random_uuid(),
            group_record.id,
            current_week_start,
            current_week_start + INTERVAL '6 days',
            EXTRACT(WEEK FROM current_week_start),
            0.026, -- 2.6%
            0.005, -- 月曜 0.5%
            0.006, -- 火曜 0.6%
            0.005, -- 水曜 0.5%
            0.005, -- 木曜 0.5%
            0.005, -- 金曜 0.5%
            'manual_fixed',
            NOW(),
            NOW()
        );
        
        insert_count := insert_count + 1;
        debug_msg := '✅ ' || group_record.group_name || 'に週利設定を強制作成';
        RAISE NOTICE '%', debug_msg;
    END LOOP;
    
    debug_msg := '🎯 週利設定強制作成完了: ' || insert_count || '件';
    RAISE NOTICE '%', debug_msg;
END $$;

-- 作成後の詳細確認
SELECT 
    '✅ 強制作成後の週利設定' as section,
    drg.group_name,
    gwr.weekly_rate,
    (gwr.weekly_rate * 100) || '%' as weekly_rate_display,
    gwr.week_start_date,
    gwr.created_at
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
ORDER BY drg.daily_rate_limit;

-- 管理画面用の最終確認クエリ
SELECT 
    '📊 管理画面表示用最終確認' as section,
    (SELECT COUNT(*) FROM user_nfts WHERE is_active = true AND current_investment > 0) as active_investments,
    (SELECT COUNT(*) FROM nfts WHERE is_active = true) as available_nfts,
    (SELECT COUNT(*) FROM group_weekly_rates WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day') as current_week_settings,
    (SELECT COUNT(*) FROM daily_rate_groups) as total_groups;
