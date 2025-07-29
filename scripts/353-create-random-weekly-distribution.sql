-- ランダム週利配分システム（0%の日も含む）

-- 1. 既存の関数を削除
DROP FUNCTION IF EXISTS generate_random_weekly_distribution(numeric);
DROP FUNCTION IF EXISTS set_weekly_rates_for_all_groups(date, numeric);

-- 2. 真のランダム配分関数を作成（0%の日も含む）
CREATE OR REPLACE FUNCTION generate_random_weekly_distribution(weekly_rate NUMERIC)
RETURNS TABLE(
    monday_rate NUMERIC,
    tuesday_rate NUMERIC,
    wednesday_rate NUMERIC,
    thursday_rate NUMERIC,
    friday_rate NUMERIC
) AS $$
DECLARE
    rates NUMERIC[] := ARRAY[0, 0, 0, 0, 0];
    remaining_rate NUMERIC := weekly_rate;
    active_days INTEGER;
    zero_days INTEGER;
    i INTEGER;
    day_index INTEGER;
    rate_per_day NUMERIC;
BEGIN
    -- ランダムに0-3日を0%にする（0%がない週もある）
    zero_days := floor(random() * 4)::INTEGER; -- 0, 1, 2, 3日
    
    -- 活動日数を計算
    active_days := 5 - zero_days;
    
    -- 全部0%の場合は1日だけ活動させる
    IF active_days = 0 THEN
        active_days := 1;
        zero_days := 4;
    END IF;
    
    -- ランダムに0%の日を選択
    FOR i IN 1..zero_days LOOP
        LOOP
            day_index := floor(random() * 5)::INTEGER + 1;
            EXIT WHEN rates[day_index] = 0; -- まだ0%に設定されていない日
        END LOOP;
        -- この日は0%のまま（既に0で初期化済み）
    END LOOP;
    
    -- 残りの日にランダム配分
    FOR i IN 1..5 LOOP
        IF rates[i] = 0 AND remaining_rate > 0 THEN
            -- この日が活動日の場合
            IF active_days = 1 THEN
                -- 最後の活動日なら残り全部
                rates[i] := remaining_rate;
                remaining_rate := 0;
            ELSE
                -- ランダムに配分（残りの20%-80%）
                rate_per_day := remaining_rate * (0.2 + random() * 0.6);
                rates[i] := rate_per_day;
                remaining_rate := remaining_rate - rate_per_day;
                active_days := active_days - 1;
            END IF;
        END IF;
    END LOOP;
    
    -- 端数調整（最初の活動日に追加）
    IF remaining_rate > 0 THEN
        FOR i IN 1..5 LOOP
            IF rates[i] > 0 THEN
                rates[i] := rates[i] + remaining_rate;
                EXIT;
            END IF;
        END LOOP;
    END IF;
    
    RETURN QUERY SELECT rates[1], rates[2], rates[3], rates[4], rates[5];
END;
$$ LANGUAGE plpgsql;

-- 3. 全グループに週利設定する関数
CREATE OR REPLACE FUNCTION set_weekly_rates_for_all_groups(
    target_week_start DATE,
    default_weekly_rate NUMERIC DEFAULT 0.026
)
RETURNS VOID AS $$
DECLARE
    group_record RECORD;
    distribution RECORD;
BEGIN
    -- 既存の週利データを削除
    DELETE FROM group_weekly_rates WHERE week_start_date = target_week_start;
    
    -- 各グループに対してランダム配分を適用
    FOR group_record IN
        SELECT group_name FROM daily_rate_groups ORDER BY group_name
    LOOP
        -- ランダム配分を生成
        SELECT * INTO distribution 
        FROM generate_random_weekly_distribution(default_weekly_rate);
        
        -- 週利データを挿入
        INSERT INTO group_weekly_rates (
            week_start_date,
            group_name,
            weekly_rate,
            monday_rate,
            tuesday_rate,
            wednesday_rate,
            thursday_rate,
            friday_rate
        ) VALUES (
            target_week_start,
            group_record.group_name,
            default_weekly_rate,
            distribution.monday_rate,
            distribution.tuesday_rate,
            distribution.wednesday_rate,
            distribution.thursday_rate,
            distribution.friday_rate
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 4. 今週の週利をランダム配分で設定（0%の日も含む）
SELECT set_weekly_rates_for_all_groups(DATE_TRUNC('week', CURRENT_DATE)::DATE, 0.026);

-- 5. ランダム配分結果を確認
SELECT 
    '🎲 ランダム週利配分結果（0%の日も含む）' as status,
    group_name,
    ROUND(weekly_rate * 100, 2) || '%' as weekly_rate,
    CASE WHEN monday_rate = 0 THEN '0%' ELSE ROUND(monday_rate * 100, 2) || '%' END as monday_rate,
    CASE WHEN tuesday_rate = 0 THEN '0%' ELSE ROUND(tuesday_rate * 100, 2) || '%' END as tuesday_rate,
    CASE WHEN wednesday_rate = 0 THEN '0%' ELSE ROUND(wednesday_rate * 100, 2) || '%' END as wednesday_rate,
    CASE WHEN thursday_rate = 0 THEN '0%' ELSE ROUND(thursday_rate * 100, 2) || '%' END as thursday_rate,
    CASE WHEN friday_rate = 0 THEN '0%' ELSE ROUND(friday_rate * 100, 2) || '%' END as friday_rate
FROM group_weekly_rates
WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)
ORDER BY group_name;

-- 6. 0%の日の統計を表示
SELECT 
    '📊 0%の日の統計' as status,
    group_name,
    (CASE WHEN monday_rate = 0 THEN 1 ELSE 0 END +
     CASE WHEN tuesday_rate = 0 THEN 1 ELSE 0 END +
     CASE WHEN wednesday_rate = 0 THEN 1 ELSE 0 END +
     CASE WHEN thursday_rate = 0 THEN 1 ELSE 0 END +
     CASE WHEN friday_rate = 0 THEN 1 ELSE 0 END) as zero_days_count
FROM group_weekly_rates
WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)
ORDER BY group_name;
