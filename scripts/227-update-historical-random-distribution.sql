-- 過去の週利設定をランダム配分に変更するスクリプト

-- 1. 現在の過去データの状況確認
SELECT 
    'Current Historical Data' as status,
    week_number,
    COUNT(*) as total_settings,
    AVG(monday_rate) as avg_monday,
    AVG(tuesday_rate) as avg_tuesday,
    AVG(wednesday_rate) as avg_wednesday,
    AVG(thursday_rate) as avg_thursday,
    AVG(friday_rate) as avg_friday,
    CASE 
        WHEN AVG(monday_rate) = AVG(tuesday_rate) 
         AND AVG(tuesday_rate) = AVG(wednesday_rate)
         AND AVG(wednesday_rate) = AVG(thursday_rate)
         AND AVG(thursday_rate) = AVG(friday_rate)
        THEN '均等配分'
        ELSE 'ランダム配分'
    END as distribution_type
FROM nft_weekly_rates 
WHERE week_number BETWEEN 10 AND 20
GROUP BY week_number
ORDER BY week_number;

-- 2. 改良されたランダム配分関数を作成
CREATE OR REPLACE FUNCTION generate_random_distribution(weekly_rate NUMERIC)
RETURNS TABLE(
    monday_rate NUMERIC,
    tuesday_rate NUMERIC, 
    wednesday_rate NUMERIC,
    thursday_rate NUMERIC,
    friday_rate NUMERIC
) AS $$
DECLARE
    rates NUMERIC[] := ARRAY[0.0, 0.0, 0.0, 0.0, 0.0]; -- 月〜金の初期値
    remaining NUMERIC := weekly_rate;
    active_days INTEGER;
    selected_days INTEGER[] := ARRAY[]::INTEGER[];
    day_index INTEGER;
    rate_value NUMERIC;
    total_check NUMERIC;
    diff NUMERIC;
    attempt_count INTEGER := 0;
    max_attempts INTEGER := 100;
BEGIN
    -- 1-3日をランダムに選択（より多くの0%日を作るため）
    active_days := (FLOOR(RANDOM() * 3) + 1)::INTEGER; -- 1〜3日
    
    -- ランダムに日を選択（重複なし）
    WHILE array_length(selected_days, 1) IS NULL OR array_length(selected_days, 1) < active_days LOOP
        attempt_count := attempt_count + 1;
        IF attempt_count > max_attempts THEN
            EXIT; -- 無限ループ防止
        END IF;
        
        day_index := (FLOOR(RANDOM() * 5) + 1)::INTEGER; -- 1〜5（月〜金）
        
        -- 重複チェック
        IF NOT (day_index = ANY(selected_days)) THEN
            selected_days := array_append(selected_days, day_index);
        END IF;
    END LOOP;
    
    -- 選択された日に週利を配分
    FOR i IN 1..COALESCE(array_length(selected_days, 1), 0) LOOP
        day_index := selected_days[i];
        
        IF i = array_length(selected_days, 1) THEN
            -- 最後の日は残り全部
            rates[day_index] := remaining;
        ELSE
            -- ランダムに配分（残りの10%〜70%の範囲）
            rate_value := remaining * (0.1 + RANDOM() * 0.6);
            rates[day_index] := rate_value;
            remaining := remaining - rate_value;
        END IF;
    END LOOP;
    
    -- 小数点以下2桁に丸める
    FOR i IN 1..5 LOOP
        rates[i] := ROUND(rates[i], 2);
    END LOOP;
    
    -- 合計チェックと微調整
    total_check := rates[1] + rates[2] + rates[3] + rates[4] + rates[5];
    diff := ROUND(weekly_rate - total_check, 2);
    
    IF ABS(diff) > 0.01 THEN
        -- 最後の非ゼロ要素に差分を加算
        FOR i IN REVERSE 1..5 LOOP
            IF rates[i] > 0 THEN
                rates[i] := GREATEST(0, ROUND(rates[i] + diff, 2));
                EXIT;
            END IF;
        END LOOP;
    END IF;
    
    RETURN QUERY SELECT rates[1], rates[2], rates[3], rates[4], rates[5];
END;
$$ LANGUAGE plpgsql;

-- 3. テスト用：ランダム配分のサンプル生成
SELECT 
    'Random Distribution Test' as test_type,
    generate_random_distribution(1.17) as sample_1,
    generate_random_distribution(2.34) as sample_2,
    generate_random_distribution(0.89) as sample_3;

SELECT 'Functions created successfully' as status;
