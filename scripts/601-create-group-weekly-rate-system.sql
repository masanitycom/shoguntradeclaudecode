-- グループ別週利設定システム

-- 既存の関数を削除
DROP FUNCTION IF EXISTS set_group_weekly_rate(DATE, TEXT, NUMERIC);
DROP FUNCTION IF EXISTS set_all_groups_weekly_rate(DATE, NUMERIC);
DROP FUNCTION IF EXISTS check_weekly_rate(DATE);
DROP FUNCTION IF EXISTS list_configured_weeks();

-- グループ別週利設定関数
CREATE OR REPLACE FUNCTION set_group_weekly_rate(
    p_week_start_date DATE,
    p_group_name TEXT,
    p_weekly_rate NUMERIC
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    week_end_date DATE;
    group_id UUID;
    rates NUMERIC[] := ARRAY[0, 0, 0, 0, 0];
    remaining_rate NUMERIC;
    random_rate NUMERIC;
    i INTEGER;
BEGIN
    week_end_date := p_week_start_date + 4;
    
    SELECT id INTO group_id FROM daily_rate_groups WHERE group_name = p_group_name;
    
    IF group_id IS NULL THEN
        RETURN QUERY SELECT false, format('グループ "%s" が見つかりません', p_group_name);
        RETURN;
    END IF;
    
    DELETE FROM group_weekly_rates 
    WHERE week_start_date = p_week_start_date AND group_id = set_group_weekly_rate.group_id;
    
    remaining_rate := p_weekly_rate / 100;
    
    FOR i IN 1..5 LOOP
        IF i = 5 THEN
            rates[i] := remaining_rate;
        ELSE
            IF remaining_rate > 0 THEN
                random_rate := ROUND((random() * remaining_rate * 0.7)::NUMERIC, 4);
                IF random() < 0.1 THEN
                    random_rate := 0;
                END IF;
                rates[i] := random_rate;
                remaining_rate := remaining_rate - random_rate;
            ELSE
                rates[i] := 0;
            END IF;
        END IF;
    END LOOP;
    
    INSERT INTO group_weekly_rates (
        group_id,
        week_start_date,
        week_end_date,
        weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        distribution_method
    ) VALUES (
        set_group_weekly_rate.group_id,
        p_week_start_date,
        week_end_date,
        p_weekly_rate / 100,
        rates[1],
        rates[2],
        rates[3],
        rates[4],
        rates[5],
        'random'
    );
    
    RETURN QUERY SELECT true, format('%s: %s%%設定完了', p_group_name, p_weekly_rate);
END;
$$ LANGUAGE plpgsql;

-- 週利確認関数
CREATE OR REPLACE FUNCTION check_weekly_rate(
    p_week_start_date DATE
) RETURNS TABLE(
    group_name TEXT,
    weekly_rate_percent NUMERIC,
    monday_percent NUMERIC,
    tuesday_percent NUMERIC,
    wednesday_percent NUMERIC,
    thursday_percent NUMERIC,
    friday_percent NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        drg.group_name::TEXT,
        ROUND(gwr.weekly_rate * 100, 2),
        ROUND(gwr.monday_rate * 100, 2),
        ROUND(gwr.tuesday_rate * 100, 2),
        ROUND(gwr.wednesday_rate * 100, 2),
        ROUND(gwr.thursday_rate * 100, 2),
        ROUND(gwr.friday_rate * 100, 2)
    FROM group_weekly_rates gwr
    JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    WHERE gwr.week_start_date = p_week_start_date
    ORDER BY drg.daily_rate_limit;
END;
$$ LANGUAGE plpgsql;

-- 設定済み週一覧
CREATE OR REPLACE FUNCTION list_configured_weeks()
RETURNS TABLE(
    week_start_date DATE,
    groups_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwr.week_start_date,
        COUNT(DISTINCT gwr.group_id)
    FROM group_weekly_rates gwr
    GROUP BY gwr.week_start_date
    ORDER BY gwr.week_start_date DESC;
END;
$$ LANGUAGE plpgsql;

-- 利用可能グループ表示
CREATE OR REPLACE FUNCTION show_available_groups()
RETURNS TABLE(
    group_name TEXT,
    daily_rate_limit_percent TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        drg.group_name::TEXT,
        ROUND(drg.daily_rate_limit * 100, 2) || '%'
    FROM daily_rate_groups drg
    ORDER BY drg.daily_rate_limit;
END;
$$ LANGUAGE plpgsql;
