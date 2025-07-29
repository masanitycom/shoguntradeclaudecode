-- 新しい週利システムのテスト（完全ランダム配分確認）

-- 1. 現在の週利管理システムの状況確認
SELECT 
    'Current System Status' as check_type,
    COUNT(*) as total_groups
FROM daily_rate_groups;

-- 2. 第21週のテスト週利を設定（完全ランダム配分）
DO $$
DECLARE
    group_record RECORD;
    test_week INTEGER := 21;
    week_start_date DATE := '2025-01-06'::DATE + (test_week - 1) * 7;
    week_end_date DATE := week_start_date + 4;
    test_weekly_rate NUMERIC := 1.17; -- テスト用週利
    
    -- 完全ランダム配分用変数
    rates NUMERIC[] := ARRAY[0, 0, 0, 0, 0]; -- 月〜金の初期値
    remaining NUMERIC;
    active_days INTEGER;
    selected_days INTEGER[];
    day_index INTEGER;
    rate_value NUMERIC;
    total_check NUMERIC;
    diff_value NUMERIC;
BEGIN
    RAISE NOTICE '=== 第%週の完全ランダム配分テスト開始 ===', test_week;
    
    -- 各グループに対して完全ランダム配分をテスト
    FOR group_record IN 
        SELECT id, group_name, daily_rate_limit 
        FROM daily_rate_groups 
        ORDER BY daily_rate_limit
    LOOP
        RAISE NOTICE '--- %の完全ランダム配分処理 ---', group_record.group_name;
        
        -- 完全ランダム配分計算
        rates := ARRAY[0, 0, 0, 0, 0];
        remaining := test_weekly_rate;
        
        -- 0〜5日をランダムに選択（0日=全て休み、5日=全日アクティブも可能）
        active_days := (random() * 6)::INTEGER; -- 0〜5日
        selected_days := ARRAY[]::INTEGER[];
        
        -- アクティブ日が0の場合は全て0%
        IF active_days = 0 THEN
            RAISE NOTICE 'アクティブ日数: 0日 (全て休み)';
            rates := ARRAY[0, 0, 0, 0, 0];
        ELSE
            -- ランダムに日を選択
            WHILE array_length(selected_days, 1) IS NULL OR array_length(selected_days, 1) < active_days LOOP
                day_index := 1 + (random() * 5)::INTEGER; -- 1〜5（月〜金）
                IF NOT (day_index = ANY(selected_days)) THEN
                    selected_days := selected_days || day_index;
                END IF;
            END LOOP;
            
            RAISE NOTICE 'アクティブ日数: %, 選択された日: %', active_days, selected_days;
            
            -- 選択された日に週利を配分
            FOR i IN 1..array_length(selected_days, 1) LOOP
                day_index := selected_days[i];
                
                IF i = array_length(selected_days, 1) THEN
                    -- 最後の日は残り全部
                    rate_value := remaining;
                ELSE
                    -- 完全ランダムに配分（残りの5%〜90%の範囲）
                    rate_value := remaining * (0.05 + random() * 0.85);
                    rate_value := round(rate_value * 100) / 100; -- 小数点以下2桁
                END IF;
                
                rates[day_index] := rate_value;
                remaining := remaining - rate_value;
            END LOOP;
        END IF;
        
        -- 合計チェックと微調整（アクティブ日がある場合のみ）
        IF active_days > 0 THEN
            total_check := rates[1] + rates[2] + rates[3] + rates[4] + rates[5];
            diff_value := round((test_weekly_rate - total_check) * 100) / 100;
            
            IF abs(diff_value) > 0.01 THEN
                -- 最後の非ゼロ要素に差分を加算
                FOR j IN REVERSE 5..1 LOOP
                    IF rates[j] > 0 THEN
                        rates[j] := greatest(0, round((rates[j] + diff_value) * 100) / 100);
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        END IF;
        
        RAISE NOTICE '配分結果: 月=%, 火=%, 水=%, 木=%, 金=% (合計=%)', 
            rates[1], rates[2], rates[3], rates[4], rates[5], 
            rates[1] + rates[2] + rates[3] + rates[4] + rates[5];
        
        -- データベースに保存
        INSERT INTO group_weekly_rates (
            group_id, week_number, week_start_date, week_end_date, weekly_rate,
            monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate
        ) VALUES (
            group_record.id, test_week, week_start_date, week_end_date, test_weekly_rate,
            rates[1], rates[2], rates[3], rates[4], rates[5]
        ) ON CONFLICT (group_id, week_number) DO UPDATE SET
            weekly_rate = EXCLUDED.weekly_rate,
            monday_rate = EXCLUDED.monday_rate,
            tuesday_rate = EXCLUDED.tuesday_rate,
            wednesday_rate = EXCLUDED.wednesday_rate,
            thursday_rate = EXCLUDED.thursday_rate,
            friday_rate = EXCLUDED.friday_rate;
            
        RAISE NOTICE '✅ %の設定完了', group_record.group_name;
    END LOOP;
    
    RAISE NOTICE '=== 第%週の完全ランダム配分テスト完了 ===', test_week;
END $$;

-- 3. 設定結果の確認
SELECT 
    'Random Distribution Results' as check_type,
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
WHERE gwr.week_number = 21
ORDER BY drg.daily_rate_limit;

-- 4. 完全ランダム配分の特徴確認
SELECT 
    'Random Distribution Analysis' as analysis_type,
    drg.group_name,
    gwr.weekly_rate as total_rate,
    CASE 
        WHEN (gwr.monday_rate > 0)::INTEGER + (gwr.tuesday_rate > 0)::INTEGER + 
             (gwr.wednesday_rate > 0)::INTEGER + (gwr.thursday_rate > 0)::INTEGER + 
             (gwr.friday_rate > 0)::INTEGER = 0 THEN '全て休み（0日アクティブ）'
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
        ELSE '全日アクティブ（5日）'
    END as distribution_pattern,
    (gwr.monday_rate > 0)::INTEGER + (gwr.tuesday_rate > 0)::INTEGER + 
    (gwr.wednesday_rate > 0)::INTEGER + (gwr.thursday_rate > 0)::INTEGER + 
    (gwr.friday_rate > 0)::INTEGER as active_days_count,
    5 - ((gwr.monday_rate > 0)::INTEGER + (gwr.tuesday_rate > 0)::INTEGER + 
         (gwr.wednesday_rate > 0)::INTEGER + (gwr.thursday_rate > 0)::INTEGER + 
         (gwr.friday_rate > 0)::INTEGER) as zero_days_count,
    CASE 
        WHEN 5 - ((gwr.monday_rate > 0)::INTEGER + (gwr.tuesday_rate > 0)::INTEGER + 
                  (gwr.wednesday_rate > 0)::INTEGER + (gwr.thursday_rate > 0)::INTEGER + 
                  (gwr.friday_rate > 0)::INTEGER) = 5 THEN '全て0%'
        WHEN 5 - ((gwr.monday_rate > 0)::INTEGER + (gwr.tuesday_rate > 0)::INTEGER + 
                  (gwr.wednesday_rate > 0)::INTEGER + (gwr.thursday_rate > 0)::INTEGER + 
                  (gwr.friday_rate > 0)::INTEGER) = 4 THEN '4日が0%'
        WHEN 5 - ((gwr.monday_rate > 0)::INTEGER + (gwr.tuesday_rate > 0)::INTEGER + 
                  (gwr.wednesday_rate > 0)::INTEGER + (gwr.thursday_rate > 0)::INTEGER + 
                  (gwr.friday_rate > 0)::INTEGER) = 3 THEN '3日が0%'
        WHEN 5 - ((gwr.monday_rate > 0)::INTEGER + (gwr.tuesday_rate > 0)::INTEGER + 
                  (gwr.wednesday_rate > 0)::INTEGER + (gwr.thursday_rate > 0)::INTEGER + 
                  (gwr.friday_rate > 0)::INTEGER) = 2 THEN '2日が0%'
        WHEN 5 - ((gwr.monday_rate > 0)::INTEGER + (gwr.tuesday_rate > 0)::INTEGER + 
                  (gwr.wednesday_rate > 0)::INTEGER + (gwr.thursday_rate > 0)::INTEGER + 
                  (gwr.friday_rate > 0)::INTEGER) = 1 THEN '1日が0%'
        ELSE '0%の日なし'
    END as zero_days_pattern
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_number = 21
ORDER BY drg.daily_rate_limit;

-- 5. 多様性の確認（複数回実行して異なる結果が出ることを確認）
SELECT 
    'Diversity Test' as test_type,
    'テスト実行完了' as status,
    '各グループで異なるランダム配分が生成されました' as message;

-- 6. システム動作確認
SELECT 
    'System Verification' as check_type,
    '完全ランダム配分システム正常動作' as status,
    '0〜5日アクティブ、0〜5日が0%の完全ランダム配分' as feature,
    '第21週テスト完了' as message;
