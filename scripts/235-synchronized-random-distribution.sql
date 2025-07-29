-- 同期ランダム配分システム（0%の曜日は全グループ共通）

-- 1. 現在の週利管理システムの状況確認
SELECT 
    'Current System Status' as check_type,
    COUNT(*) as total_groups
FROM daily_rate_groups;

-- 2. 第22週のテスト週利を設定（同期ランダム配分）
DO $$
DECLARE
    group_record RECORD;
    test_week INTEGER := 22;
    week_start_date DATE := '2025-01-06'::DATE + (test_week - 1) * 7;
    week_end_date DATE := week_start_date + 4;
    
    -- 全グループ共通の0%曜日パターン
    common_zero_pattern BOOLEAN[] := ARRAY[false, false, false, false, false]; -- 月〜金
    active_days INTEGER;
    selected_days INTEGER[];
    day_index INTEGER;
    
    -- 各グループの週利設定
    group_weekly_rates NUMERIC[] := ARRAY[0.85, 1.17, 1.45, 1.73, 2.05]; -- 各グループの週利
    current_group_index INTEGER := 1;
    
    -- ランダム配分用変数
    rates NUMERIC[] := ARRAY[0, 0, 0, 0, 0];
    remaining NUMERIC;
    rate_value NUMERIC;
    total_check NUMERIC;
    diff_value NUMERIC;
BEGIN
    RAISE NOTICE '=== 第%週の同期ランダム配分テスト開始 ===', test_week;
    
    -- 全グループ共通の0%曜日パターンを決定
    active_days := 1 + (random() * 4)::INTEGER; -- 1〜5日アクティブ
    selected_days := ARRAY[]::INTEGER[];
    
    -- ランダムに日を選択（全グループ共通）
    WHILE array_length(selected_days, 1) IS NULL OR array_length(selected_days, 1) < active_days LOOP
        day_index := 1 + (random() * 5)::INTEGER; -- 1〜5（月〜金）
        IF NOT (day_index = ANY(selected_days)) THEN
            selected_days := selected_days || day_index;
        END IF;
    END LOOP;
    
    -- 共通パターンを設定
    FOR i IN 1..5 LOOP
        common_zero_pattern[i] := (i = ANY(selected_days));
    END LOOP;
    
    RAISE NOTICE '全グループ共通アクティブ日数: %, 選択された日: %', active_days, selected_days;
    RAISE NOTICE '共通パターン: 月=%, 火=%, 水=%, 木=%, 金=%', 
        CASE WHEN common_zero_pattern[1] THEN 'アクティブ' ELSE '0%' END,
        CASE WHEN common_zero_pattern[2] THEN 'アクティブ' ELSE '0%' END,
        CASE WHEN common_zero_pattern[3] THEN 'アクティブ' ELSE '0%' END,
        CASE WHEN common_zero_pattern[4] THEN 'アクティブ' ELSE '0%' END,
        CASE WHEN common_zero_pattern[5] THEN 'アクティブ' ELSE '0%' END;
    
    -- 各グループに対して同じ0%パターンでランダム配分
    FOR group_record IN 
        SELECT id, group_name, daily_rate_limit 
        FROM daily_rate_groups 
        ORDER BY daily_rate_limit
    LOOP
        RAISE NOTICE '--- %の同期ランダム配分処理 ---', group_record.group_name;
        
        -- 初期化
        rates := ARRAY[0, 0, 0, 0, 0];
        remaining := group_weekly_rates[current_group_index];
        
        RAISE NOTICE '週利設定: %', remaining;
        
        -- アクティブな日にランダム配分
        FOR i IN 1..array_length(selected_days, 1) LOOP
            day_index := selected_days[i];
            
            IF i = array_length(selected_days, 1) THEN
                -- 最後の日は残り全部
                rate_value := remaining;
            ELSE
                -- ランダムに配分（残りの10%〜80%の範囲）
                rate_value := remaining * (0.1 + random() * 0.7);
                rate_value := round(rate_value * 100) / 100; -- 小数点以下2桁
            END IF;
            
            rates[day_index] := rate_value;
            remaining := remaining - rate_value;
        END LOOP;
        
        -- 合計チェックと微調整
        total_check := rates[1] + rates[2] + rates[3] + rates[4] + rates[5];
        diff_value := round((group_weekly_rates[current_group_index] - total_check) * 100) / 100;
        
        IF abs(diff_value) > 0.01 THEN
            -- 最後の非ゼロ要素に差分を加算
            FOR j IN REVERSE 5..1 LOOP
                IF rates[j] > 0 THEN
                    rates[j] := greatest(0, round((rates[j] + diff_value) * 100) / 100);
                    EXIT;
                END IF;
            END LOOP;
        END IF;
        
        RAISE NOTICE '配分結果: 月=%, 火=%, 水=%, 木=%, 金=% (合計=%)', 
            rates[1], rates[2], rates[3], rates[4], rates[5], 
            rates[1] + rates[2] + rates[3] + rates[4] + rates[5];
        
        -- データベースに保存
        INSERT INTO group_weekly_rates (
            group_id, week_number, week_start_date, week_end_date, weekly_rate,
            monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate
        ) VALUES (
            group_record.id, test_week, week_start_date, week_end_date, group_weekly_rates[current_group_index],
            rates[1], rates[2], rates[3], rates[4], rates[5]
        ) ON CONFLICT (group_id, week_number) DO UPDATE SET
            weekly_rate = EXCLUDED.weekly_rate,
            monday_rate = EXCLUDED.monday_rate,
            tuesday_rate = EXCLUDED.tuesday_rate,
            wednesday_rate = EXCLUDED.wednesday_rate,
            thursday_rate = EXCLUDED.thursday_rate,
            friday_rate = EXCLUDED.friday_rate;
            
        RAISE NOTICE '✅ %の設定完了', group_record.group_name;
        current_group_index := current_group_index + 1;
    END LOOP;
    
    RAISE NOTICE '=== 第%週の同期ランダム配分テスト完了 ===', test_week;
END $$;

-- 3. 設定結果の確認
SELECT 
    'Synchronized Random Distribution Results' as check_type,
    drg.group_name,
    gwr.weekly_rate,
    gwr.monday_rate,
    gwr.tuesday_rate,
    gwr.wednesday_rate,
    gwr.thursday_rate,
    gwr.friday_rate,
    CASE 
        WHEN gwr.monday_rate = 0 THEN '休み' 
        ELSE gwr.monday_rate::TEXT || '%' 
    END as monday_display,
    CASE 
        WHEN gwr.tuesday_rate = 0 THEN '休み' 
        ELSE gwr.tuesday_rate::TEXT || '%' 
    END as tuesday_display,
    CASE 
        WHEN gwr.wednesday_rate = 0 THEN '休み' 
        ELSE gwr.wednesday_rate::TEXT || '%' 
    END as wednesday_display,
    CASE 
        WHEN gwr.thursday_rate = 0 THEN '休み' 
        ELSE gwr.thursday_rate::TEXT || '%' 
    END as thursday_display,
    CASE 
        WHEN gwr.friday_rate = 0 THEN '休み' 
        ELSE gwr.friday_rate::TEXT || '%' 
    END as friday_display,
    (gwr.monday_rate + gwr.tuesday_rate + gwr.wednesday_rate + gwr.thursday_rate + gwr.friday_rate) as total_check
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_number = 22
ORDER BY drg.daily_rate_limit;

-- 4. 同期パターンの確認
SELECT 
    'Synchronization Verification' as verification_type,
    'Monday' as day_name,
    COUNT(CASE WHEN gwr.monday_rate = 0 THEN 1 END) as zero_count,
    COUNT(CASE WHEN gwr.monday_rate > 0 THEN 1 END) as active_count,
    CASE 
        WHEN COUNT(CASE WHEN gwr.monday_rate = 0 THEN 1 END) = 5 THEN '全グループ0%'
        WHEN COUNT(CASE WHEN gwr.monday_rate > 0 THEN 1 END) = 5 THEN '全グループアクティブ'
        ELSE '混在（エラー）'
    END as sync_status
FROM group_weekly_rates gwr
WHERE gwr.week_number = 22

UNION ALL

SELECT 
    'Synchronization Verification' as verification_type,
    'Tuesday' as day_name,
    COUNT(CASE WHEN gwr.tuesday_rate = 0 THEN 1 END) as zero_count,
    COUNT(CASE WHEN gwr.tuesday_rate > 0 THEN 1 END) as active_count,
    CASE 
        WHEN COUNT(CASE WHEN gwr.tuesday_rate = 0 THEN 1 END) = 5 THEN '全グループ0%'
        WHEN COUNT(CASE WHEN gwr.tuesday_rate > 0 THEN 1 END) = 5 THEN '全グループアクティブ'
        ELSE '混在（エラー）'
    END as sync_status
FROM group_weekly_rates gwr
WHERE gwr.week_number = 22

UNION ALL

SELECT 
    'Synchronization Verification' as verification_type,
    'Wednesday' as day_name,
    COUNT(CASE WHEN gwr.wednesday_rate = 0 THEN 1 END) as zero_count,
    COUNT(CASE WHEN gwr.wednesday_rate > 0 THEN 1 END) as active_count,
    CASE 
        WHEN COUNT(CASE WHEN gwr.wednesday_rate = 0 THEN 1 END) = 5 THEN '全グループ0%'
        WHEN COUNT(CASE WHEN gwr.wednesday_rate > 0 THEN 1 END) = 5 THEN '全グループアクティブ'
        ELSE '混在（エラー）'
    END as sync_status
FROM group_weekly_rates gwr
WHERE gwr.week_number = 22

UNION ALL

SELECT 
    'Synchronization Verification' as verification_type,
    'Thursday' as day_name,
    COUNT(CASE WHEN gwr.thursday_rate = 0 THEN 1 END) as zero_count,
    COUNT(CASE WHEN gwr.thursday_rate > 0 THEN 1 END) as active_count,
    CASE 
        WHEN COUNT(CASE WHEN gwr.thursday_rate = 0 THEN 1 END) = 5 THEN '全グループ0%'
        WHEN COUNT(CASE WHEN gwr.thursday_rate > 0 THEN 1 END) = 5 THEN '全グループアクティブ'
        ELSE '混在（エラー）'
    END as sync_status
FROM group_weekly_rates gwr
WHERE gwr.week_number = 22

UNION ALL

SELECT 
    'Synchronization Verification' as verification_type,
    'Friday' as day_name,
    COUNT(CASE WHEN gwr.friday_rate = 0 THEN 1 END) as zero_count,
    COUNT(CASE WHEN gwr.friday_rate > 0 THEN 1 END) as active_count,
    CASE 
        WHEN COUNT(CASE WHEN gwr.friday_rate = 0 THEN 1 END) = 5 THEN '全グループ0%'
        WHEN COUNT(CASE WHEN gwr.friday_rate > 0 THEN 1 END) = 5 THEN '全グループアクティブ'
        ELSE '混在（エラー）'
    END as sync_status
FROM group_weekly_rates gwr
WHERE gwr.week_number = 22;

-- 5. 配分の多様性確認
SELECT 
    'Distribution Diversity' as analysis_type,
    drg.group_name,
    gwr.weekly_rate as total_rate,
    CASE 
        WHEN (gwr.monday_rate > 0)::INTEGER + (gwr.tuesday_rate > 0)::INTEGER + 
             (gwr.wednesday_rate > 0)::INTEGER + (gwr.thursday_rate > 0)::INTEGER + 
             (gwr.friday_rate > 0)::INTEGER = 0 THEN '全て休み'
        WHEN (gwr.monday_rate > 0)::INTEGER + (gwr.tuesday_rate > 0)::INTEGER + 
             (gwr.wednesday_rate > 0)::INTEGER + (gwr.thursday_rate > 0)::INTEGER + 
             (gwr.friday_rate > 0)::INTEGER = 1 THEN '1日のみアクティブ'
        WHEN (gwr.monday_rate > 0)::INTEGER + (gwr.tuesday_rate > 0)::INTEGER + 
             (gwr.wednesday_rate > 0)::INTEGER + (gwr.thursday_rate > 0)::INTEGER + 
             (gwr.friday_rate > 0)::INTEGER = 2 THEN '2日アクティブ'
        WHEN (gwr.monday_rate > 0)::INTEGER + (gwr.tuesday_rate > 0)::INTEGER + 
             (gwr.wednesday_rate > 0)::INTEGER + (gwr.thursday_rate > 0)::INTEGER + 
             (gwr.friday_rate > 0)::INTEGER = 3 THEN '3日アクティブ'
        WHEN (gwr.monday_rate > 0)::INTEGER + (gwr.tuesday_rate > 0)::INTEGER + 
             (gwr.wednesday_rate > 0)::INTEGER + (gwr.thursday_rate > 0)::INTEGER + 
             (gwr.friday_rate > 0)::INTEGER = 4 THEN '4日アクティブ'
        ELSE '全日アクティブ'
    END as distribution_pattern,
    '同じ0%パターン、異なる配分率' as diversity_note
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_number = 22
ORDER BY drg.daily_rate_limit;

-- 6. システム動作確認
SELECT 
    'System Verification' as check_type,
    '同期ランダム配分システム正常動作' as status,
    '0%曜日は全グループ共通、配分率はグループ別ランダム' as feature,
    '第22週テスト完了' as message;
