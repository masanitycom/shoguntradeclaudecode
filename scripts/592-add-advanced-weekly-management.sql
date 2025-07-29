-- 高度な週利管理機能を追加
-- 個別週設定、グループ別設定、一括変更機能

-- 1. 特定の週とグループの週利を個別設定
CREATE OR REPLACE FUNCTION set_specific_group_weekly_rate(
    p_week_start_date DATE,
    p_group_name TEXT,
    p_weekly_rate NUMERIC,
    p_distribution_method TEXT DEFAULT 'random'
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    group_id_val UUID;
    week_end_date DATE;
    rates NUMERIC[] := ARRAY[0, 0, 0, 0, 0];
    remaining_rate NUMERIC;
    random_rate NUMERIC;
    i INTEGER;
    admin_user_id UUID;
BEGIN
    -- グループIDを取得
    SELECT id INTO group_id_val FROM daily_rate_groups WHERE group_name = p_group_name;
    
    IF group_id_val IS NULL THEN
        RETURN QUERY SELECT false, format('グループ "%s" が見つかりません', p_group_name);
        RETURN;
    END IF;
    
    -- 管理者ユーザーIDを取得
    SELECT id INTO admin_user_id FROM users WHERE user_id = 'admin001' LIMIT 1;
    
    -- 週末日を計算
    week_end_date := p_week_start_date + 4;
    
    -- 既存データを削除
    DELETE FROM group_weekly_rates 
    WHERE group_id = group_id_val AND week_start_date = p_week_start_date;
    
    -- 日利分配を計算
    remaining_rate := p_weekly_rate / 100;
    
    IF p_distribution_method = 'equal' THEN
        -- 均等分配
        FOR i IN 1..5 LOOP
            rates[i] := remaining_rate / 5;
        END LOOP;
    ELSE
        -- ランダム分配
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
    END IF;
    
    -- データを挿入
    INSERT INTO group_weekly_rates (
        group_id, week_start_date, week_end_date, weekly_rate,
        monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate,
        distribution_method, created_by
    ) VALUES (
        group_id_val, p_week_start_date, week_end_date, p_weekly_rate / 100,
        rates[1], rates[2], rates[3], rates[4], rates[5],
        p_distribution_method, admin_user_id
    );
    
    RETURN QUERY SELECT 
        true, 
        format('グループ "%s" の週利%s%%を%sに設定しました', 
               p_group_name, p_weekly_rate, p_week_start_date::TEXT);
END;
$$ LANGUAGE plpgsql;

-- 2. 週利設定の一括変更
CREATE OR REPLACE FUNCTION bulk_update_weekly_rates(
    p_start_date DATE,
    p_end_date DATE,
    p_old_rate NUMERIC,
    p_new_rate NUMERIC
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    updated_count INTEGER
) AS $$
DECLARE
    update_count INTEGER;
BEGIN
    UPDATE group_weekly_rates 
    SET weekly_rate = p_new_rate / 100,
        monday_rate = monday_rate * (p_new_rate / p_old_rate),
        tuesday_rate = tuesday_rate * (p_new_rate / p_old_rate),
        wednesday_rate = wednesday_rate * (p_new_rate / p_old_rate),
        thursday_rate = thursday_rate * (p_new_rate / p_old_rate),
        friday_rate = friday_rate * (p_new_rate / p_old_rate)
    WHERE week_start_date BETWEEN p_start_date AND p_end_date
    AND ABS(weekly_rate * 100 - p_old_rate) < 0.01;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true,
        format('%s件の週利を%s%%から%s%%に変更しました', 
               update_count, p_old_rate, p_new_rate),
        update_count;
END;
$$ LANGUAGE plpgsql;

-- 3. 週利設定の検索・フィルタ機能
CREATE OR REPLACE FUNCTION search_weekly_rates(
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_group_name TEXT DEFAULT NULL,
    p_min_rate NUMERIC DEFAULT NULL,
    p_max_rate NUMERIC DEFAULT NULL
) RETURNS TABLE(
    week_start_date DATE,
    week_end_date DATE,
    group_name TEXT,
    weekly_rate_percent NUMERIC,
    monday_rate_percent NUMERIC,
    tuesday_rate_percent NUMERIC,
    wednesday_rate_percent NUMERIC,
    thursday_rate_percent NUMERIC,
    friday_rate_percent NUMERIC,
    distribution_method TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwr.week_start_date,
        gwr.week_end_date,
        drg.group_name,
        ROUND(gwr.weekly_rate * 100, 2) as weekly_rate_percent,
        ROUND(gwr.monday_rate * 100, 2) as monday_rate_percent,
        ROUND(gwr.tuesday_rate * 100, 2) as tuesday_rate_percent,
        ROUND(gwr.wednesday_rate * 100, 2) as wednesday_rate_percent,
        ROUND(gwr.thursday_rate * 100, 2) as thursday_rate_percent,
        ROUND(gwr.friday_rate * 100, 2) as friday_rate_percent,
        COALESCE(gwr.distribution_method, 'random') as distribution_method
    FROM group_weekly_rates gwr
    JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    WHERE (p_start_date IS NULL OR gwr.week_start_date >= p_start_date)
    AND (p_end_date IS NULL OR gwr.week_start_date <= p_end_date)
    AND (p_group_name IS NULL OR drg.group_name ILIKE '%' || p_group_name || '%')
    AND (p_min_rate IS NULL OR gwr.weekly_rate * 100 >= p_min_rate)
    AND (p_max_rate IS NULL OR gwr.weekly_rate * 100 <= p_max_rate)
    ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit;
END;
$$ LANGUAGE plpgsql;

-- 4. 週利統計情報
CREATE OR REPLACE FUNCTION get_weekly_rates_statistics()
RETURNS TABLE(
    total_weeks INTEGER,
    total_groups INTEGER,
    avg_weekly_rate NUMERIC,
    min_weekly_rate NUMERIC,
    max_weekly_rate NUMERIC,
    most_common_rate NUMERIC,
    earliest_week DATE,
    latest_week DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(DISTINCT gwr.week_start_date)::INTEGER as total_weeks,
        COUNT(DISTINCT gwr.group_id)::INTEGER as total_groups,
        ROUND(AVG(gwr.weekly_rate * 100), 2) as avg_weekly_rate,
        ROUND(MIN(gwr.weekly_rate * 100), 2) as min_weekly_rate,
        ROUND(MAX(gwr.weekly_rate * 100), 2) as max_weekly_rate,
        ROUND(MODE() WITHIN GROUP (ORDER BY gwr.weekly_rate) * 100, 2) as most_common_rate,
        MIN(gwr.week_start_date) as earliest_week,
        MAX(gwr.week_start_date) as latest_week
    FROM group_weekly_rates gwr;
END;
$$ LANGUAGE plpgsql;

-- 5. 週利管理UIのための拡張関数
CREATE OR REPLACE FUNCTION get_weekly_rates_for_date_range(
    p_start_date DATE,
    p_end_date DATE
) RETURNS TABLE(
    week_start_date DATE,
    week_end_date DATE,
    group_name TEXT,
    daily_rate_limit NUMERIC,
    weekly_rate_percent NUMERIC,
    monday_percent NUMERIC,
    tuesday_percent NUMERIC,
    wednesday_percent NUMERIC,
    thursday_percent NUMERIC,
    friday_percent NUMERIC,
    distribution_method TEXT,
    total_weekly_percent NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwr.week_start_date,
        gwr.week_end_date,
        drg.group_name,
        drg.daily_rate_limit,
        ROUND(gwr.weekly_rate * 100, 2) as weekly_rate_percent,
        ROUND(gwr.monday_rate * 100, 2) as monday_percent,
        ROUND(gwr.tuesday_rate * 100, 2) as tuesday_percent,
        ROUND(gwr.wednesday_rate * 100, 2) as wednesday_percent,
        ROUND(gwr.thursday_rate * 100, 2) as thursday_percent,
        ROUND(gwr.friday_rate * 100, 2) as friday_percent,
        COALESCE(gwr.distribution_method, 'random') as distribution_method,
        ROUND((gwr.monday_rate + gwr.tuesday_rate + gwr.wednesday_rate + gwr.thursday_rate + gwr.friday_rate) * 100, 2) as total_weekly_percent
    FROM group_weekly_rates gwr
    JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    WHERE gwr.week_start_date BETWEEN p_start_date AND p_end_date
    ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit;
END;
$$ LANGUAGE plpgsql;

-- 6. 週利設定の削除機能
CREATE OR REPLACE FUNCTION delete_weekly_rates(
    p_week_start_date DATE,
    p_group_name TEXT DEFAULT NULL
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    deleted_count INTEGER
) AS $$
DECLARE
    delete_count INTEGER;
BEGIN
    IF p_group_name IS NOT NULL THEN
        -- 特定グループの週利を削除
        DELETE FROM group_weekly_rates gwr
        USING daily_rate_groups drg
        WHERE gwr.group_id = drg.id
        AND gwr.week_start_date = p_week_start_date
        AND drg.group_name = p_group_name;
    ELSE
        -- 指定週の全グループの週利を削除
        DELETE FROM group_weekly_rates 
        WHERE week_start_date = p_week_start_date;
    END IF;
    
    GET DIAGNOSTICS delete_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true,
        format('%s件の週利設定を削除しました', delete_count),
        delete_count;
END;
$$ LANGUAGE plpgsql;

-- 完了メッセージ
SELECT 'Advanced weekly management functions created successfully' as status;

-- 作成された関数の一覧表示
SELECT 
    'Created Functions' as category,
    proname as function_name,
    pg_get_function_arguments(oid) as arguments
FROM pg_proc 
WHERE proname IN (
    'set_specific_group_weekly_rate',
    'bulk_update_weekly_rates',
    'search_weekly_rates',
    'get_weekly_rates_statistics',
    'get_weekly_rates_for_date_range',
    'delete_weekly_rates'
)
ORDER BY proname;
