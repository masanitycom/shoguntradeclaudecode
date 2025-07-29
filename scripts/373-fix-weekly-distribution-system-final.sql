-- 正確な週利配分システムの実装

-- 1. 既存の不正確な関数を削除
DROP FUNCTION IF EXISTS create_synchronized_weekly_distribution(date, uuid, numeric);
DROP FUNCTION IF EXISTS generate_random_weekly_distribution(numeric);

-- 2. 正確な配分を生成する関数
CREATE OR REPLACE FUNCTION generate_exact_weekly_distribution(
    target_weekly_rate NUMERIC,
    daily_limit NUMERIC
)
RETURNS TABLE(
    monday_rate NUMERIC,
    tuesday_rate NUMERIC,
    wednesday_rate NUMERIC,
    thursday_rate NUMERIC,
    friday_rate NUMERIC,
    total_rate NUMERIC,
    is_valid BOOLEAN
) AS $$
DECLARE
    remaining_rate NUMERIC := target_weekly_rate;
    rates NUMERIC[] := ARRAY[0, 0, 0, 0, 0];
    day_index INTEGER;
    max_for_day NUMERIC;
    allocated_rate NUMERIC;
BEGIN
    -- 理論上限チェック
    IF target_weekly_rate > (daily_limit * 5) THEN
        RETURN QUERY SELECT 0::NUMERIC, 0::NUMERIC, 0::NUMERIC, 0::NUMERIC, 0::NUMERIC, 0::NUMERIC, false;
        RETURN;
    END IF;
    
    -- ランダムに日を選んで配分
    FOR i IN 1..5 LOOP
        day_index := (random() * 4)::INTEGER + 1;
        
        -- この日に割り当て可能な最大値
        max_for_day := LEAST(daily_limit, remaining_rate);
        
        -- 残り日数を考慮した配分
        IF i = 5 THEN
            -- 最後の日は残り全部
            allocated_rate := remaining_rate;
        ELSE
            -- ランダムに0から最大値まで
            allocated_rate := random() * max_for_day;
        END IF;
        
        -- 上限チェック
        allocated_rate := LEAST(allocated_rate, daily_limit);
        
        -- 配分
        rates[day_index] := rates[day_index] + allocated_rate;
        remaining_rate := remaining_rate - allocated_rate;
        
        -- 残りがマイナスになったら調整
        IF remaining_rate < 0 THEN
            rates[day_index] := rates[day_index] + remaining_rate;
            remaining_rate := 0;
        END IF;
        
        -- 各日の上限チェック
        IF rates[day_index] > daily_limit THEN
            remaining_rate := remaining_rate + (rates[day_index] - daily_limit);
            rates[day_index] := daily_limit;
        END IF;
    END LOOP;
    
    -- 残りがある場合は再配分
    WHILE remaining_rate > 0.0001 LOOP
        FOR day_index IN 1..5 LOOP
            IF remaining_rate <= 0.0001 THEN
                EXIT;
            END IF;
            
            max_for_day := daily_limit - rates[day_index];
            IF max_for_day > 0 THEN
                allocated_rate := LEAST(max_for_day, remaining_rate);
                rates[day_index] := rates[day_index] + allocated_rate;
                remaining_rate := remaining_rate - allocated_rate;
            END IF;
        END LOOP;
        
        -- 無限ループ防止
        IF remaining_rate > 0.0001 THEN
            EXIT;
        END IF;
    END LOOP;
    
    -- 結果を返す
    RETURN QUERY SELECT 
        rates[1], rates[2], rates[3], rates[4], rates[5],
        rates[1] + rates[2] + rates[3] + rates[4] + rates[5],
        ABS((rates[1] + rates[2] + rates[3] + rates[4] + rates[5]) - target_weekly_rate) < 0.0001;
END;
$$ LANGUAGE plpgsql;

-- 3. 正確な週利配分システムを作成
CREATE OR REPLACE FUNCTION create_exact_weekly_distribution(
    p_week_start_date DATE,
    p_group_id UUID,
    p_weekly_rate NUMERIC
)
RETURNS VOID AS $$
DECLARE
    group_daily_limit NUMERIC;
    distribution_record RECORD;
    max_attempts INTEGER := 100;
    attempt INTEGER := 0;
    success BOOLEAN := false;
    week_end_date DATE;
    week_number INTEGER;
BEGIN
    -- グループの日利上限を取得
    SELECT daily_rate_limit / 100.0 INTO group_daily_limit
    FROM daily_rate_groups
    WHERE id = p_group_id;
    
    IF group_daily_limit IS NULL THEN
        RAISE EXCEPTION 'グループが見つかりません: %', p_group_id;
    END IF;
    
    -- 週利が理論上限を超える場合はエラー
    IF p_weekly_rate > (group_daily_limit * 5) THEN
        RAISE EXCEPTION '週利%.2f%%は日利上限%.2f%%×5日=%.2f%%を超えています', 
            p_weekly_rate * 100, group_daily_limit * 100, group_daily_limit * 5 * 100;
    END IF;
    
    -- 正確な配分を生成（複数回試行）
    WHILE attempt < max_attempts AND NOT success LOOP
        attempt := attempt + 1;
        
        SELECT * INTO distribution_record
        FROM generate_exact_weekly_distribution(p_weekly_rate, group_daily_limit);
        
        IF distribution_record.is_valid AND 
           ABS(distribution_record.total_rate - p_weekly_rate) < 0.0001 THEN
            success := true;
        END IF;
    END LOOP;
    
    IF NOT success THEN
        RAISE EXCEPTION '週利%.2f%%の正確な配分生成に失敗しました', p_weekly_rate * 100;
    END IF;
    
    -- 週の終了日と週番号を計算
    week_end_date := p_week_start_date + INTERVAL '6 days';
    week_number := EXTRACT(week FROM p_week_start_date);
    
    -- 既存データを削除
    DELETE FROM group_weekly_rates 
    WHERE week_start_date = p_week_start_date AND group_id = p_group_id;
    
    -- 新しいデータを挿入
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
        p_group_id,
        p_week_start_date,
        week_end_date,
        week_number,
        p_weekly_rate,
        distribution_record.monday_rate,
        distribution_record.tuesday_rate,
        distribution_record.wednesday_rate,
        distribution_record.thursday_rate,
        distribution_record.friday_rate,
        'exact_auto',
        NOW(),
        NOW()
    );
END;
$$ LANGUAGE plpgsql;

-- 4. 全グループに正確な週利を設定する関数
CREATE OR REPLACE FUNCTION set_exact_weekly_rates_for_all_groups(
    target_week_start DATE,
    default_weekly_rate NUMERIC DEFAULT 0.018
)
RETURNS VOID AS $$
DECLARE
    group_record RECORD;
    total_groups INTEGER := 0;
    success_count INTEGER := 0;
BEGIN
    FOR group_record IN
        SELECT id, group_name, daily_rate_limit
        FROM daily_rate_groups 
        ORDER BY group_name
    LOOP
        total_groups := total_groups + 1;
        
        BEGIN
            PERFORM create_exact_weekly_distribution(
                target_week_start,
                group_record.id,
                default_weekly_rate
            );
            success_count := success_count + 1;
                
        EXCEPTION WHEN OTHERS THEN
            -- エラーは無視して続行
            NULL;
        END;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 5. 今週に週利1.8%を正確配分で適用
SELECT set_exact_weekly_rates_for_all_groups(
    DATE_TRUNC('week', CURRENT_DATE)::DATE + INTERVAL '1 day',
    0.018
);
