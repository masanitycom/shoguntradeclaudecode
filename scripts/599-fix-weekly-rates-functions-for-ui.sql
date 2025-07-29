-- 管理画面用の関数を修正（グループ別週利設定対応）

-- 1. 既存の問題のある関数を削除
DROP FUNCTION IF EXISTS get_weekly_rates_with_groups();
DROP FUNCTION IF EXISTS get_system_status();
DROP FUNCTION IF EXISTS check_weekly_rate(DATE);
DROP FUNCTION IF EXISTS set_week_2_10_rate();
DROP FUNCTION IF EXISTS check_february_weeks();
DROP FUNCTION IF EXISTS set_custom_weekly_rate(DATE, NUMERIC);

-- 2. データ型を統一した週利取得関数
CREATE OR REPLACE FUNCTION get_weekly_rates_with_groups()
RETURNS TABLE (
    id TEXT,
    week_start_date TEXT,
    week_end_date TEXT,
    weekly_rate NUMERIC,
    monday_rate NUMERIC,
    tuesday_rate NUMERIC,
    wednesday_rate NUMERIC,
    thursday_rate NUMERIC,
    friday_rate NUMERIC,
    group_name TEXT,
    distribution_method TEXT
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwr.id::TEXT,
        gwr.week_start_date::TEXT,
        gwr.week_end_date::TEXT,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        drg.group_name::TEXT,
        COALESCE(gwr.distribution_method, 'random')::TEXT
    FROM group_weekly_rates gwr
    JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit;
END;
$$;

-- 3. システム状況取得関数（reward_amountカラム対応）
CREATE OR REPLACE FUNCTION get_system_status()
RETURNS TABLE (
    total_users BIGINT,
    active_nfts BIGINT,
    pending_rewards NUMERIC,
    last_calculation TEXT,
    current_week_rates BIGINT
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM users WHERE is_admin = false)::BIGINT,
        (SELECT COUNT(*) FROM user_nfts WHERE is_active = true)::BIGINT,
        (SELECT COALESCE(SUM(reward_amount), 0) FROM daily_rewards WHERE created_at >= CURRENT_DATE - INTERVAL '7 days')::NUMERIC,
        (SELECT COALESCE(MAX(created_at)::TEXT, 'Never') FROM daily_rewards)::TEXT,
        (SELECT COUNT(DISTINCT week_start_date) FROM group_weekly_rates WHERE week_start_date >= CURRENT_DATE - INTERVAL '7 days')::BIGINT;
END;
$$;

-- 4. 週利確認関数（データ型エラーを修正）
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
        drg.group_name::TEXT,
        ROUND(gwr.weekly_rate * 100, 2) as weekly_rate_percent,
        ROUND(gwr.monday_rate * 100, 2) as monday_percent,
        ROUND(gwr.tuesday_rate * 100, 2) as tuesday_percent,
        ROUND(gwr.wednesday_rate * 100, 2) as wednesday_percent,
        ROUND(gwr.thursday_rate * 100, 2) as thursday_percent,
        ROUND(gwr.friday_rate * 100, 2) as friday_percent,
        COALESCE(gwr.distribution_method, 'random')::TEXT as distribution_method
    FROM group_weekly_rates gwr
    JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    WHERE gwr.week_start_date = p_week_start_date
    ORDER BY drg.daily_rate_limit;
END;
$$ LANGUAGE plpgsql;

-- 5. グループ別週利設定関数
CREATE OR REPLACE FUNCTION set_group_weekly_rate(
    p_week_start_date DATE,
    p_group_name TEXT,
    p_weekly_rate NUMERIC
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    group_name TEXT,
    weekly_rate NUMERIC
) AS $$
DECLARE
    week_end_date DATE;
    group_id UUID;
    rates NUMERIC[] := ARRAY[0, 0, 0, 0, 0]; -- 月火水木金
    remaining_rate NUMERIC;
    random_rate NUMERIC;
    i INTEGER;
BEGIN
    -- 週末日を計算（金曜日）
    week_end_date := p_week_start_date + 4;
    
    -- グループIDを取得
    SELECT id INTO group_id FROM daily_rate_groups WHERE group_name = p_group_name;
    
    IF group_id IS NULL THEN
        RETURN QUERY SELECT 
            false,
            format('グループ "%s" が見つかりません', p_group_name),
            p_group_name,
            p_weekly_rate;
        RETURN;
    END IF;
    
    -- 既存の同じ週・グループのデータを削除
    DELETE FROM group_weekly_rates 
    WHERE week_start_date = p_week_start_date AND group_id = set_group_weekly_rate.group_id;
    
    remaining_rate := p_weekly_rate / 100; -- パーセントを小数に変換
    
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
    
    -- グループ別週利データを挿入
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
    
    RETURN QUERY SELECT 
        true,
        format('%sに週利%s%%を設定しました（%s〜%s）', 
               p_group_name, 
               p_weekly_rate, 
               p_week_start_date::TEXT, 
               week_end_date::TEXT),
        p_group_name,
        p_weekly_rate;
END;
$$ LANGUAGE plpgsql;

-- 6. 全グループ一括設定関数（デフォルト週利で）
CREATE OR REPLACE FUNCTION set_all_groups_weekly_rate(
    p_week_start_date DATE,
    p_base_weekly_rate NUMERIC DEFAULT 2.6
) RETURNS TABLE(
    group_name TEXT,
    weekly_rate NUMERIC,
    message TEXT
) AS $$
DECLARE
    group_record RECORD;
    adjusted_rate NUMERIC;
BEGIN
    FOR group_record IN 
        SELECT id, group_name, daily_rate_limit FROM daily_rate_groups ORDER BY daily_rate_limit
    LOOP
        -- グループの日利上限に応じて週利を調整
        CASE 
            WHEN group_record.daily_rate_limit = 0.005 THEN adjusted_rate := p_base_weekly_rate * 0.6; -- 0.5%グループ
            WHEN group_record.daily_rate_limit = 0.010 THEN adjusted_rate := p_base_weekly_rate * 0.8; -- 1.0%グループ
            WHEN group_record.daily_rate_limit = 0.0125 THEN adjusted_rate := p_base_weekly_rate * 0.9; -- 1.25%グループ
            WHEN group_record.daily_rate_limit = 0.015 THEN adjusted_rate := p_base_weekly_rate; -- 1.5%グループ
            WHEN group_record.daily_rate_limit = 0.0175 THEN adjusted_rate := p_base_weekly_rate * 1.1; -- 1.75%グループ
            WHEN group_record.daily_rate_limit = 0.020 THEN adjusted_rate := p_base_weekly_rate * 1.2; -- 2.0%グループ
            ELSE adjusted_rate := p_base_weekly_rate;
        END CASE;
        
        -- グループ別に設定
        PERFORM set_group_weekly_rate(p_week_start_date, group_record.group_name, adjusted_rate);
        
        RETURN QUERY SELECT 
            group_record.group_name,
            adjusted_rate,
            format('週利%s%%を設定', adjusted_rate);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 7. 設定済み週の一覧表示
CREATE OR REPLACE FUNCTION list_configured_weeks()
RETURNS TABLE(
    week_start_date DATE,
    week_end_date DATE,
    groups_configured BIGINT,
    week_info TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwr.week_start_date,
        gwr.week_end_date,
        COUNT(DISTINCT gwr.group_id) as groups_configured,
        format('%s〜%s (%s groups)', 
               gwr.week_start_date::TEXT, 
               gwr.week_end_date::TEXT,
               COUNT(DISTINCT gwr.group_id)) as week_info
    FROM group_weekly_rates gwr
    GROUP BY gwr.week_start_date, gwr.week_end_date
    ORDER BY gwr.week_start_date DESC;
END;
$$ LANGUAGE plpgsql;

-- 完了メッセージ
SELECT 'Fixed weekly rate management functions for group-based setting' as status;
