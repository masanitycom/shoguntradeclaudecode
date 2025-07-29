-- 週利設定を復元・再作成

DO $$
DECLARE
    current_week_start DATE;
    group_record RECORD;
    insert_count INTEGER := 0;
    debug_msg TEXT;
BEGIN
    debug_msg := '🚀 週利設定の復元を開始';
    RAISE NOTICE '%', debug_msg;
    
    -- 今週の月曜日を計算
    current_week_start := DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day';
    
    debug_msg := '📅 今週の開始日: ' || current_week_start;
    RAISE NOTICE '%', debug_msg;
    
    -- 既存の今週設定を削除
    DELETE FROM group_weekly_rates 
    WHERE week_start_date = current_week_start;
    
    debug_msg := '🗑️ 既存の今週設定を削除';
    RAISE NOTICE '%', debug_msg;
    
    -- 各グループに今週の週利設定を作成
    FOR group_record IN 
        SELECT id, group_name, daily_rate_limit 
        FROM daily_rate_groups 
        ORDER BY daily_rate_limit
    LOOP
        -- 週利2.6%をランダムに月〜金に配分
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
            'random_distribution',
            NOW(),
            NOW()
        );
        
        insert_count := insert_count + 1;
        debug_msg := '✅ ' || group_record.group_name || 'に週利設定を追加';
        RAISE NOTICE '%', debug_msg;
    END LOOP;
    
    debug_msg := '🎯 週利設定復元完了: ' || insert_count || '件作成';
    RAISE NOTICE '%', debug_msg;
END $$;

-- 復元後の確認
SELECT 
    '✅ 復元された週利設定' as status,
    drg.group_name,
    gwr.weekly_rate,
    (gwr.weekly_rate * 100) || '%' as weekly_rate_display,
    gwr.monday_rate,
    gwr.tuesday_rate,
    gwr.wednesday_rate,
    gwr.thursday_rate,
    gwr.friday_rate,
    gwr.week_start_date
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day'
ORDER BY drg.daily_rate_limit;

-- システム状況の確認
SELECT 
    '📊 システム状況確認' as section,
    (SELECT COUNT(*) FROM user_nfts WHERE is_active = true AND current_investment > 0) as active_investments,
    (SELECT COUNT(*) FROM nfts WHERE is_active = true) as available_nfts,
    (SELECT COUNT(*) FROM group_weekly_rates WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day') as current_week_settings,
    CASE 
        WHEN EXTRACT(DOW FROM CURRENT_DATE) BETWEEN 1 AND 5 THEN '計算可能'
        ELSE '計算不可'
    END as calculation_status;
