-- すべての管理関数を正しい構造で再作成

-- 1. 既存の関数をすべて削除
DROP FUNCTION IF EXISTS admin_create_backup(DATE);
DROP FUNCTION IF EXISTS admin_delete_weekly_rates(DATE);
DROP FUNCTION IF EXISTS admin_restore_from_backup(DATE, TIMESTAMP WITH TIME ZONE);
DROP FUNCTION IF EXISTS show_available_groups();
DROP FUNCTION IF EXISTS get_system_status();
DROP FUNCTION IF EXISTS calculate_daily_rewards_for_week(DATE);
DROP FUNCTION IF EXISTS calculate_daily_rewards_for_date(DATE);
DROP FUNCTION IF EXISTS force_daily_calculation();

-- 2. show_available_groups関数
CREATE OR REPLACE FUNCTION show_available_groups()
RETURNS TABLE(
    group_id UUID,
    group_name TEXT,
    nft_count BIGINT,
    total_investment NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        drg.id as group_id,
        drg.group_name,
        COUNT(n.id) as nft_count,
        COALESCE(SUM(n.price), 0) as total_investment
    FROM daily_rate_groups drg
    LEFT JOIN nfts n ON n.daily_rate_group_id = drg.id
    GROUP BY drg.id, drg.group_name
    ORDER BY drg.group_name;
END;
$$ LANGUAGE plpgsql;

-- 3. get_system_status関数
CREATE OR REPLACE FUNCTION get_system_status()
RETURNS TABLE(
    metric_name TEXT,
    metric_value TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 'Total Users'::TEXT, COUNT(*)::TEXT FROM users
    UNION ALL
    SELECT 'Total NFTs'::TEXT, COUNT(*)::TEXT FROM nfts
    UNION ALL
    SELECT 'Active User NFTs'::TEXT, COUNT(*)::TEXT FROM user_nfts WHERE is_active = true
    UNION ALL
    SELECT 'Total Groups'::TEXT, COUNT(*)::TEXT FROM daily_rate_groups
    UNION ALL
    SELECT 'Current Week Rates'::TEXT, COUNT(*)::TEXT FROM group_weekly_rates 
    WHERE week_start_date = date_trunc('week', CURRENT_DATE)::DATE
    UNION ALL
    SELECT 'Backup Records'::TEXT, COUNT(*)::TEXT FROM group_weekly_rates_backup;
END;
$$ LANGUAGE plpgsql;

-- 4. admin_create_backup関数
CREATE OR REPLACE FUNCTION admin_create_backup(
    p_week_start_date DATE
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    backup_count INTEGER := 0;
BEGIN
    -- バックアップ作成
    INSERT INTO group_weekly_rates_backup (
        original_id,
        group_id,
        week_start_date,
        week_end_date,
        weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        distribution_method,
        backup_reason,
        backup_timestamp
    )
    SELECT 
        gwr.id,
        gwr.group_id,
        gwr.week_start_date,
        gwr.week_end_date,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        gwr.distribution_method,
        'Manual backup via admin UI',
        NOW()
    FROM group_weekly_rates gwr
    WHERE gwr.week_start_date = p_week_start_date;
    
    GET DIAGNOSTICS backup_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true,
        format('%sの週利設定を%s件バックアップしました', p_week_start_date::TEXT, backup_count);
END;
$$ LANGUAGE plpgsql;

-- 5. admin_delete_weekly_rates関数
CREATE OR REPLACE FUNCTION admin_delete_weekly_rates(
    p_week_start_date DATE
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    deleted_count INTEGER := 0;
    backup_result RECORD;
BEGIN
    -- バックアップ作成
    SELECT * INTO backup_result FROM admin_create_backup(p_week_start_date);
    
    -- 削除実行
    DELETE FROM group_weekly_rates 
    WHERE week_start_date = p_week_start_date;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true,
        format('%sの週利設定を%s件削除しました（バックアップ済み）', p_week_start_date::TEXT, deleted_count);
END;
$$ LANGUAGE plpgsql;

-- 6. admin_restore_from_backup関数
CREATE OR REPLACE FUNCTION admin_restore_from_backup(
    p_week_start_date DATE,
    p_backup_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NULL
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    restored_count INTEGER := 0;
    backup_time TIMESTAMP WITH TIME ZONE;
BEGIN
    -- バックアップタイムスタンプ決定
    IF p_backup_timestamp IS NULL THEN
        SELECT MAX(backup_timestamp) INTO backup_time
        FROM group_weekly_rates_backup
        WHERE week_start_date = p_week_start_date;
    ELSE
        backup_time := p_backup_timestamp;
    END IF;
    
    IF backup_time IS NULL THEN
        RETURN QUERY SELECT 
            false,
            format('%sのバックアップが見つかりません', p_week_start_date::TEXT);
        RETURN;
    END IF;
    
    -- 既存データ削除
    DELETE FROM group_weekly_rates WHERE week_start_date = p_week_start_date;
    
    -- バックアップから復元
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
    )
    SELECT 
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
    FROM group_weekly_rates_backup
    WHERE week_start_date = p_week_start_date 
    AND backup_timestamp = backup_time;
    
    GET DIAGNOSTICS restored_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true,
        format('%sの週利設定を%s件復元しました', p_week_start_date::TEXT, restored_count);
END;
$$ LANGUAGE plpgsql;

-- 7. calculate_daily_rewards_for_week関数
CREATE OR REPLACE FUNCTION calculate_daily_rewards_for_week(
    p_week_start_date DATE
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    calculated_records INTEGER
) AS $$
DECLARE
    calc_date DATE;
    total_records INTEGER := 0;
    daily_records INTEGER;
BEGIN
    calc_date := p_week_start_date;
    
    -- 月曜から金曜まで計算
    FOR i IN 0..4 LOOP
        SELECT COUNT(*) INTO daily_records 
        FROM calculate_daily_rewards_for_date(calc_date);
        
        total_records := total_records + daily_records;
        calc_date := calc_date + INTERVAL '1 day';
    END LOOP;
    
    RETURN QUERY SELECT 
        true,
        format('%sの週の日利を計算しました', p_week_start_date::TEXT),
        total_records;
END;
$$ LANGUAGE plpgsql;

-- 8. calculate_daily_rewards_for_date関数
CREATE OR REPLACE FUNCTION calculate_daily_rewards_for_date(
    p_date DATE
) RETURNS TABLE(
    user_nft_id UUID,
    reward_amount NUMERIC,
    calculation_date DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        un.id as user_nft_id,
        CASE 
            WHEN EXTRACT(DOW FROM p_date) IN (1,2,3,4,5) THEN -- 平日のみ
                LEAST(
                    un.investment_amount * 
                    CASE EXTRACT(DOW FROM p_date)
                        WHEN 1 THEN gwr.monday_rate
                        WHEN 2 THEN gwr.tuesday_rate
                        WHEN 3 THEN gwr.wednesday_rate
                        WHEN 4 THEN gwr.thursday_rate
                        WHEN 5 THEN gwr.friday_rate
                        ELSE 0
                    END / 100,
                    n.daily_rate_limit - COALESCE(un.total_rewards_received, 0)
                )
            ELSE 0
        END as reward_amount,
        p_date as calculation_date
    FROM user_nfts un
    JOIN nfts n ON un.nft_id = n.id
    JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
    JOIN group_weekly_rates gwr ON gwr.group_id = drg.id
    WHERE un.is_active = true
    AND gwr.week_start_date = date_trunc('week', p_date)::DATE
    AND un.purchase_date <= p_date
    AND COALESCE(un.total_rewards_received, 0) < n.daily_rate_limit;
END;
$$ LANGUAGE plpgsql;

-- 9. force_daily_calculation関数
CREATE OR REPLACE FUNCTION force_daily_calculation()
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    calculation_date DATE,
    processed_records INTEGER
) AS $$
DECLARE
    today_date DATE := CURRENT_DATE;
    processed_count INTEGER := 0;
BEGIN
    -- 今日の日利計算を実行
    INSERT INTO daily_rewards (
        user_nft_id,
        reward_amount,
        reward_date,
        created_at
    )
    SELECT 
        cdr.user_nft_id,
        cdr.reward_amount,
        cdr.calculation_date,
        NOW()
    FROM calculate_daily_rewards_for_date(today_date) cdr
    WHERE cdr.reward_amount > 0
    ON CONFLICT (user_nft_id, reward_date) DO UPDATE SET
        reward_amount = EXCLUDED.reward_amount,
        updated_at = NOW();
    
    GET DIAGNOSTICS processed_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true,
        format('今日（%s）の日利計算を実行しました', today_date::TEXT),
        today_date,
        processed_count;
END;
$$ LANGUAGE plpgsql;

SELECT 'All admin functions recreated successfully!' as status;
