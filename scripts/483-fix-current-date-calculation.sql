-- 現在の日付を正しく取得して、正確な週利設定を作成

-- 1. まず全ての偽データを削除
DELETE FROM group_weekly_rates;

-- 2. 現在の日付を確認
SELECT 
    '📅 現在の日付確認' as section,
    CURRENT_DATE as today,
    EXTRACT(DOW FROM CURRENT_DATE) as day_of_week,
    (CURRENT_DATE - EXTRACT(DOW FROM CURRENT_DATE)::INTEGER + 1) as this_monday;

-- 3. 正しい今週の月曜日を計算して週利設定を作成
DO $$
DECLARE
    today_date DATE := CURRENT_DATE;
    this_monday DATE;
    week_date DATE;
    group_rec RECORD;
    week_counter INTEGER := 0;
BEGIN
    -- 今週の月曜日を正確に計算
    -- DOW: 0=日曜, 1=月曜, 2=火曜, ..., 6=土曜
    this_monday := today_date - (EXTRACT(DOW FROM today_date)::INTEGER - 1);
    
    -- 日曜日の場合は前週の月曜日にする
    IF EXTRACT(DOW FROM today_date) = 0 THEN
        this_monday := this_monday - INTERVAL '6 days';
    END IF;
    
    RAISE NOTICE '今日: %, 今週の月曜日: %', today_date, this_monday;
    
    -- 今週から過去4週間分を作成
    FOR i IN 0..4 LOOP
        week_date := this_monday - (i || ' weeks')::INTERVAL;
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
                week_date::DATE,
                0.026, -- 2.6%
                0.0052, -- 月曜 0.52%
                0.0052, -- 火曜 0.52%
                0.0052, -- 水曜 0.52%
                0.0052, -- 木曜 0.52%
                0.0052, -- 金曜 0.52%
                NOW(),
                NOW()
            );
        END LOOP;
    END LOOP;
    
    RAISE NOTICE '週利設定復元完了: %週間分', week_counter;
END $$;

-- 4. 復元結果を確認
SELECT 
    '✅ 正しい日付での復元結果' as section,
    week_start_date,
    (week_start_date + INTERVAL '6 days')::DATE as week_end_date,
    COUNT(*) as group_count,
    AVG(weekly_rate * 100) as avg_weekly_rate
FROM group_weekly_rates
GROUP BY week_start_date
ORDER BY week_start_date DESC;

-- 5. 今日が何曜日で、どの週に属するかを確認
SELECT 
    '📊 現在の状況確認' as section,
    CURRENT_DATE as today,
    CASE EXTRACT(DOW FROM CURRENT_DATE)
        WHEN 0 THEN '日曜日'
        WHEN 1 THEN '月曜日'
        WHEN 2 THEN '火曜日'
        WHEN 3 THEN '水曜日'
        WHEN 4 THEN '木曜日'
        WHEN 5 THEN '金曜日'
        WHEN 6 THEN '土曜日'
    END as day_name,
    (SELECT week_start_date FROM group_weekly_rates 
     WHERE week_start_date <= CURRENT_DATE 
     ORDER BY week_start_date DESC LIMIT 1) as current_week_start;
