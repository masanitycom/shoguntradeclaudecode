-- デモ用週利設定（来週分）

-- 1. 来週の月曜日を計算
WITH next_week AS (
    SELECT 
        CURRENT_DATE + (8 - EXTRACT(DOW FROM CURRENT_DATE)::INTEGER) as next_monday
)
SELECT 
    '📅 来週の設定デモ' as section,
    next_monday as target_week,
    next_monday + 6 as week_end,
    '来週分の週利設定をデモ実行します' as description
FROM next_week;

-- 2. 来週分のグループ別週利設定（デモ）
DO $$
DECLARE
    next_monday_date DATE;
    group_record RECORD;
    demo_weekly_rates NUMERIC[] := ARRAY[0.015, 0.020, 0.023, 0.026, 0.029, 0.032]; -- 1.5%, 2.0%, 2.3%, 2.6%, 2.9%, 3.2%
    rate_index INTEGER := 1;
BEGIN
    -- 来週の月曜日を計算
    next_monday_date := CURRENT_DATE + (8 - EXTRACT(DOW FROM CURRENT_DATE)::INTEGER);
    
    RAISE NOTICE '📅 来週（%）の週利設定デモを開始', next_monday_date;
    
    -- 各グループに対してデモ週利を設定
    FOR group_record IN 
        SELECT id, group_name, daily_rate_limit 
        FROM daily_rate_groups 
        ORDER BY daily_rate_limit
    LOOP
        -- グループ別の週利設定
        INSERT INTO group_weekly_rates (
            id,
            week_start_date,
            week_end_date,
            weekly_rate,
            monday_rate,
            tuesday_rate,
            wednesday_rate,
            thursday_rate,
            friday_rate,
            group_id,
            group_name,
            distribution_method,
            created_at,
            updated_at
        ) VALUES (
            gen_random_uuid(),
            next_monday_date,
            next_monday_date + 6,
            demo_weekly_rates[rate_index],
            demo_weekly_rates[rate_index] * 0.20, -- 月曜 20%
            demo_weekly_rates[rate_index] * 0.25, -- 火曜 25%
            demo_weekly_rates[rate_index] * 0.20, -- 水曜 20%
            demo_weekly_rates[rate_index] * 0.20, -- 木曜 20%
            demo_weekly_rates[rate_index] * 0.15, -- 金曜 15%
            group_record.id,
            group_record.group_name,
            'DEMO_SETTING',
            NOW(),
            NOW()
        )
        ON CONFLICT (week_start_date, group_id) 
        DO UPDATE SET
            weekly_rate = demo_weekly_rates[rate_index],
            monday_rate = demo_weekly_rates[rate_index] * 0.20,
            tuesday_rate = demo_weekly_rates[rate_index] * 0.25,
            wednesday_rate = demo_weekly_rates[rate_index] * 0.20,
            thursday_rate = demo_weekly_rates[rate_index] * 0.20,
            friday_rate = demo_weekly_rates[rate_index] * 0.15,
            distribution_method = 'DEMO_SETTING',
            updated_at = NOW();
        
        RAISE NOTICE '✅ % グループ: 週利%% 設定完了', group_record.group_name, (demo_weekly_rates[rate_index] * 100)::NUMERIC(5,3);
        
        rate_index := rate_index + 1;
        IF rate_index > array_length(demo_weekly_rates, 1) THEN
            rate_index := array_length(demo_weekly_rates, 1); -- 最後の値を使用
        END IF;
    END LOOP;
    
    RAISE NOTICE '🎉 来週分の週利設定デモが完了しました';
END $$;

-- 3. 設定結果確認
SELECT 
    '✅ デモ設定結果確認' as section,
    gwr.week_start_date,
    gwr.group_name,
    (gwr.weekly_rate * 100)::NUMERIC(5,3) as weekly_rate_percent,
    (gwr.monday_rate * 100)::NUMERIC(5,3) as monday_percent,
    (gwr.tuesday_rate * 100)::NUMERIC(5,3) as tuesday_percent,
    (gwr.wednesday_rate * 100)::NUMERIC(5,3) as wednesday_percent,
    (gwr.thursday_rate * 100)::NUMERIC(5,3) as thursday_percent,
    (gwr.friday_rate * 100)::NUMERIC(5,3) as friday_percent,
    gwr.distribution_method
FROM group_weekly_rates gwr
WHERE gwr.week_start_date = CURRENT_DATE + (8 - EXTRACT(DOW FROM CURRENT_DATE)::INTEGER)
ORDER BY gwr.group_name;

-- 4. 管理画面アクセス情報
SELECT 
    '🎛️ 管理画面アクセス情報' as section,
    '/admin/weekly-rates' as admin_url,
    '週利設定・バックアップ・復元が可能' as features,
    'admin001 / password123 でログイン' as login_info,
    '設定変更時は自動バックアップされます' as safety_note;
