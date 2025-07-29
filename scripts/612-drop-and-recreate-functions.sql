-- 既存の関数を削除してから再作成

-- 1. 既存の関数を削除
DROP FUNCTION IF EXISTS calculate_daily_rewards_for_date(DATE);
DROP FUNCTION IF EXISTS calculate_daily_rewards_for_week(DATE);
DROP FUNCTION IF EXISTS show_available_groups();
DROP FUNCTION IF EXISTS list_weekly_rates_backups();
DROP FUNCTION IF EXISTS force_daily_calculation();
DROP FUNCTION IF EXISTS get_system_status();

-- 2. show_available_groups関数を作成
CREATE OR REPLACE FUNCTION show_available_groups()
RETURNS TABLE(
    group_name TEXT,
    daily_rate_limit_percent NUMERIC,
    nft_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        drg.group_name::TEXT,
        ROUND(drg.daily_rate_limit * 100, 2) as daily_rate_limit_percent,
        COUNT(n.id) as nft_count
    FROM daily_rate_groups drg
    LEFT JOIN nfts n ON n.daily_rate_limit = drg.daily_rate_limit
    GROUP BY drg.id, drg.group_name, drg.daily_rate_limit
    ORDER BY drg.daily_rate_limit;
END;
$$ LANGUAGE plpgsql;

-- 3. list_weekly_rates_backups関数を作成
CREATE OR REPLACE FUNCTION list_weekly_rates_backups()
RETURNS TABLE(
    week_start_date DATE,
    backup_timestamp TIMESTAMP WITH TIME ZONE,
    backup_reason TEXT,
    group_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwrb.week_start_date,
        gwrb.backup_timestamp,
        gwrb.backup_reason,
        COUNT(*) as group_count
    FROM group_weekly_rates_backup gwrb
    GROUP BY gwrb.week_start_date, gwrb.backup_timestamp, gwrb.backup_reason
    ORDER BY gwrb.backup_timestamp DESC;
END;
$$ LANGUAGE plpgsql;

-- 4. calculate_daily_rewards_for_date関数を作成
CREATE OR REPLACE FUNCTION calculate_daily_rewards_for_date(
    p_date DATE
) RETURNS TABLE(
    user_id UUID,
    user_nft_id UUID,
    amount NUMERIC
) AS $$
DECLARE
    day_of_week INTEGER;
    rate_column TEXT;
BEGIN
    -- 曜日を取得（1=月曜, 2=火曜, ..., 5=金曜）
    day_of_week := EXTRACT(DOW FROM p_date);
    
    -- 土日は計算しない
    IF day_of_week = 0 OR day_of_week = 6 THEN
        RETURN;
    END IF;
    
    -- 曜日に対応するレートカラムを決定
    rate_column := CASE day_of_week
        WHEN 1 THEN 'monday_rate'
        WHEN 2 THEN 'tuesday_rate'
        WHEN 3 THEN 'wednesday_rate'
        WHEN 4 THEN 'thursday_rate'
        WHEN 5 THEN 'friday_rate'
    END;
    
    -- 日利計算を実行
    RETURN QUERY
    EXECUTE format('
        SELECT 
            un.user_id,
            un.id as user_nft_id,
            LEAST(
                un.purchase_amount * gwr.%I,
                n.daily_rate_limit * un.purchase_amount
            ) as amount
        FROM user_nfts un
        JOIN nfts n ON un.nft_id = n.id
        JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
        JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
        WHERE un.is_active = true
        AND un.purchase_date <= $1
        AND gwr.week_start_date <= $1
        AND gwr.week_end_date >= $1
        AND un.total_rewards_received < (un.purchase_amount * 3)
    ', rate_column)
    USING p_date;
END;
$$ LANGUAGE plpgsql;

-- 5. calculate_daily_rewards_for_week関数を作成
CREATE OR REPLACE FUNCTION calculate_daily_rewards_for_week(
    p_week_start_date DATE
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    calculated_days INTEGER,
    total_rewards NUMERIC
) AS $$
DECLARE
    calc_date DATE;
    end_date DATE;
    calculated_count INTEGER := 0;
    total_amount NUMERIC := 0;
    daily_amount NUMERIC;
BEGIN
    calc_date := p_week_start_date;
    end_date := p_week_start_date + 4; -- 金曜日まで
    
    WHILE calc_date <= end_date LOOP
        -- 平日のみ計算（月曜=1, 火曜=2, 水曜=3, 木曜=4, 金曜=5）
        IF EXTRACT(DOW FROM calc_date) BETWEEN 1 AND 5 THEN
            -- その日の日利計算を実行
            SELECT COALESCE(SUM(amount), 0) INTO daily_amount
            FROM calculate_daily_rewards_for_date(calc_date);
            
            total_amount := total_amount + daily_amount;
            calculated_count := calculated_count + 1;
        END IF;
        
        calc_date := calc_date + 1;
    END LOOP;
    
    RETURN QUERY SELECT 
        true,
        format('週間計算完了: %s週 (%s日間)', p_week_start_date, calculated_count),
        calculated_count,
        total_amount;
END;
$$ LANGUAGE plpgsql;

-- 6. force_daily_calculation関数を作成
CREATE OR REPLACE FUNCTION force_daily_calculation()
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    processed_users INTEGER
) AS $$
DECLARE
    processed_count INTEGER := 0;
    current_week_start DATE;
BEGIN
    -- 今週の月曜日を取得
    current_week_start := DATE_TRUNC('week', CURRENT_DATE) + 1;
    
    -- 今週の日利計算を実行
    SELECT calculated_days INTO processed_count
    FROM calculate_daily_rewards_for_week(current_week_start);
    
    RETURN QUERY SELECT 
        true,
        format('日利計算完了: %s件処理', processed_count),
        processed_count;
        
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 
        false,
        format('日利計算エラー: %s', SQLERRM),
        0;
END;
$$ LANGUAGE plpgsql;

-- 7. get_system_status関数を作成
CREATE OR REPLACE FUNCTION get_system_status()
RETURNS TABLE(
    total_users BIGINT,
    active_nfts BIGINT,
    pending_rewards NUMERIC,
    last_calculation TEXT,
    current_week_rates BIGINT,
    total_backups BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM users WHERE is_admin = false) as total_users,
        (SELECT COUNT(*) FROM user_nfts WHERE is_active = true) as active_nfts,
        COALESCE((SELECT SUM(amount) FROM daily_rewards WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'), 0) as pending_rewards,
        COALESCE((SELECT MAX(created_at)::TEXT FROM daily_rewards), '未実行') as last_calculation,
        (SELECT COUNT(DISTINCT week_start_date) FROM group_weekly_rates) as current_week_rates,
        (SELECT COUNT(DISTINCT week_start_date || backup_timestamp::TEXT) FROM group_weekly_rates_backup) as total_backups;
END;
$$ LANGUAGE plpgsql;

SELECT 'Successfully dropped and recreated all functions' as status;
