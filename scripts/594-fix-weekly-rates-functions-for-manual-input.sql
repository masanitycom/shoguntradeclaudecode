-- 手動週利設定用の修正版関数を作成
-- created_byカラムを削除し、シンプルな手動入力に対応

-- 1. 既存の問題のある関数を削除
DROP FUNCTION IF EXISTS set_historical_weekly_rate(DATE, NUMERIC, TEXT, UUID);
DROP FUNCTION IF EXISTS bulk_set_historical_rates(DATE, DATE, NUMERIC, TEXT);
DROP FUNCTION IF EXISTS set_specific_group_weekly_rate(DATE, TEXT, NUMERIC, TEXT);

-- 2. シンプルな週利設定関数（手動入力用）
CREATE OR REPLACE FUNCTION set_weekly_rate_manual(
    p_week_start_date DATE,
    p_weekly_rate NUMERIC,
    p_distribution_method TEXT DEFAULT 'random'
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    records_created INTEGER
) AS $$
DECLARE
    week_end_date DATE;
    group_record RECORD;
    rates NUMERIC[] := ARRAY[0, 0, 0, 0, 0]; -- 月火水木金
    remaining_rate NUMERIC;
    random_rate NUMERIC;
    i INTEGER;
    records_count INTEGER := 0;
BEGIN
    -- 週末日を計算（金曜日）
    week_end_date := p_week_start_date + 4;
    
    -- 既存の同じ週のデータを削除
    DELETE FROM group_weekly_rates WHERE week_start_date = p_week_start_date;
    
    -- 各グループに対して週利を設定
    FOR group_record IN 
        SELECT id, group_name FROM daily_rate_groups ORDER BY daily_rate_limit
    LOOP
        remaining_rate := p_weekly_rate / 100; -- パーセントを小数に変換
        
        -- 分配方法に応じて日利を計算
        IF p_distribution_method = 'equal' THEN
            -- 均等分配
            FOR i IN 1..5 LOOP
                rates[i] := remaining_rate / 5;
            END LOOP;
        ELSE
            -- ランダム分配
            FOR i IN 1..5 LOOP
                IF i = 5 THEN
                    -- 最後の日は残り全部
                    rates[i] := remaining_rate;
                ELSE
                    -- ランダムに0%から残り利率の70%まで
                    IF remaining_rate > 0 THEN
                        random_rate := ROUND((random() * remaining_rate * 0.7)::NUMERIC, 4);
                        -- 10%の確率で0%にする
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
        
        -- グループ別週利データを挿入（created_byカラムを除外）
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
            group_record.id,
            p_week_start_date,
            week_end_date,
            p_weekly_rate / 100,
            rates[1],
            rates[2],
            rates[3],
            rates[4],
            rates[5],
            p_distribution_method
        );
        
        records_count := records_count + 1;
    END LOOP;
    
    RETURN QUERY SELECT 
        true,
        format('週利%s%%を%sに手動設定しました（%s件のグループ）', 
               p_weekly_rate, 
               p_week_start_date::TEXT, 
               records_count),
        records_count;
END;
$$ LANGUAGE plpgsql;

-- 3. 特定の週の週利を確認する関数
CREATE OR REPLACE FUNCTION check_weekly_rate(
    p_week_start_date DATE
) RETURNS TABLE(
    group_name TEXT,
    weekly_rate_percent NUMERIC,
    monday_percent NUMERIC,
    tuesday_percent NUMERIC,
    wednesday_percent NUMERIC,
    thursday_percent NUMERIC,
    friday_percent NUMERIC,
    distribution_method TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        drg.group_name,
        ROUND(gwr.weekly_rate * 100, 2) as weekly_rate_percent,
        ROUND(gwr.monday_rate * 100, 2) as monday_percent,
        ROUND(gwr.tuesday_rate * 100, 2) as tuesday_percent,
        ROUND(gwr.wednesday_rate * 100, 2) as wednesday_percent,
        ROUND(gwr.thursday_rate * 100, 2) as thursday_percent,
        ROUND(gwr.friday_rate * 100, 2) as friday_percent,
        COALESCE(gwr.distribution_method, 'random') as distribution_method
    FROM group_weekly_rates gwr
    JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    WHERE gwr.week_start_date = p_week_start_date
    ORDER BY drg.daily_rate_limit;
END;
$$ LANGUAGE plpgsql;

-- 4. 週利設定済みの週を一覧表示
CREATE OR REPLACE FUNCTION list_configured_weeks()
RETURNS TABLE(
    week_start_date DATE,
    week_end_date DATE,
    groups_configured INTEGER,
    avg_weekly_rate_percent NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwr.week_start_date,
        gwr.week_end_date,
        COUNT(*)::INTEGER as groups_configured,
        ROUND(AVG(gwr.weekly_rate * 100), 2) as avg_weekly_rate_percent
    FROM group_weekly_rates gwr
    GROUP BY gwr.week_start_date, gwr.week_end_date
    ORDER BY gwr.week_start_date DESC;
END;
$$ LANGUAGE plpgsql;

-- 5. 週利削除関数（手動管理用）
CREATE OR REPLACE FUNCTION delete_weekly_rate(
    p_week_start_date DATE
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    deleted_count INTEGER
) AS $$
DECLARE
    delete_count INTEGER;
BEGIN
    DELETE FROM group_weekly_rates 
    WHERE week_start_date = p_week_start_date;
    
    GET DIAGNOSTICS delete_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true,
        format('%sの週利設定を削除しました（%s件）', 
               p_week_start_date::TEXT, delete_count),
        delete_count;
END;
$$ LANGUAGE plpgsql;

-- 完了メッセージ
SELECT 'Manual weekly rate management functions created successfully' as status;

-- 作成された関数の確認
SELECT 
    'Manual Functions' as category,
    proname as function_name,
    pg_get_function_arguments(oid) as arguments
FROM pg_proc 
WHERE proname IN (
    'set_weekly_rate_manual',
    'check_weekly_rate',
    'list_configured_weeks',
    'delete_weekly_rate'
)
ORDER BY proname;
