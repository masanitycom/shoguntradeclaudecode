-- 全グループの週利設定を作成

DO $$
DECLARE
    debug_msg TEXT;
    target_week_start DATE;
    target_week_end DATE;
    target_week_number INTEGER;
    group_record RECORD;
    insert_count INTEGER := 0;
BEGIN
    debug_msg := '📅 週利設定作成開始';
    RAISE NOTICE '%', debug_msg;
    
    -- 今週の日付を計算
    target_week_start := DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day'; -- 月曜日
    target_week_end := target_week_start + INTERVAL '6 days'; -- 日曜日
    target_week_number := EXTRACT(week FROM CURRENT_DATE)::INTEGER;
    
    debug_msg := '📅 対象週: ' || target_week_start || ' ～ ' || target_week_end || ' (第' || target_week_number || '週)';
    RAISE NOTICE '%', debug_msg;
    
    -- 既存の今週の設定を削除
    DELETE FROM group_weekly_rates 
    WHERE week_start_date = target_week_start;
    
    debug_msg := '🗑️ 既存の今週設定削除完了';
    RAISE NOTICE '%', debug_msg;
    
    -- 各グループに対して週利設定を作成
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
            target_week_start,
            target_week_end,
            target_week_number,
            0.026, -- 2.6%の週利
            0.005, -- 月曜日 0.5%
            0.006, -- 火曜日 0.6%
            0.005, -- 水曜日 0.5%
            0.005, -- 木曜日 0.5%
            0.005, -- 金曜日 0.5%
            'random_distribution',
            NOW(),
            NOW()
        );
        
        insert_count := insert_count + 1;
        debug_msg := '✅ ' || group_record.group_name || ' の週利設定作成完了';
        RAISE NOTICE '%', debug_msg;
    END LOOP;
    
    debug_msg := '🎯 週利設定作成完了: 合計 ' || insert_count || '件';
    RAISE NOTICE '%', debug_msg;
END $$;

-- 週利設定作成結果の確認
SELECT 
    '📊 週利設定作成結果' as section,
    drg.group_name,
    gwr.weekly_rate,
    (gwr.weekly_rate * 100) || '%' as weekly_rate_display,
    gwr.monday_rate || '/' || gwr.tuesday_rate || '/' || gwr.wednesday_rate || '/' || gwr.thursday_rate || '/' || gwr.friday_rate as daily_distribution,
    gwr.week_start_date,
    gwr.week_end_date
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day'
ORDER BY drg.daily_rate_limit;

-- 管理画面表示用の最終確認
SELECT 
    '📊 管理画面表示用最終確認' as section,
    (SELECT COUNT(*) FROM user_nfts WHERE is_active = true AND current_investment > 0) as active_investments,
    (SELECT COUNT(*) FROM nfts WHERE is_active = true) as available_nfts,
    (SELECT COUNT(*) FROM group_weekly_rates WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day') as current_week_settings,
    (SELECT COUNT(*) FROM daily_rate_groups) as total_groups;
