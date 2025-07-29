-- NFTとグループの関連を修正

-- 1. show_available_groups関数を修正（daily_rate_limitベース）
DROP FUNCTION IF EXISTS show_available_groups();

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
        drg.group_name::TEXT,
        COUNT(n.id) as nft_count,
        COALESCE(SUM(n.price), 0) as total_investment
    FROM daily_rate_groups drg
    LEFT JOIN nfts n ON n.daily_rate_limit = drg.daily_rate_limit
    GROUP BY drg.id, drg.group_name
    ORDER BY drg.group_name;
END;
$$ LANGUAGE plpgsql;

-- 2. calculate_daily_rewards_for_date関数を修正
DROP FUNCTION IF EXISTS calculate_daily_rewards_for_date(DATE);

CREATE OR REPLACE FUNCTION calculate_daily_rewards_for_date(
    p_date DATE
) RETURNS TABLE(
    user_id UUID,
    user_nft_id UUID,
    nft_id UUID,
    reward_amount NUMERIC,
    calculation_details TEXT
) AS $$
DECLARE
    day_of_week INTEGER;
    rate_column TEXT;
BEGIN
    -- 平日チェック（1=月曜, 5=金曜）
    day_of_week := EXTRACT(DOW FROM p_date);
    IF day_of_week NOT BETWEEN 1 AND 5 THEN
        RETURN;
    END IF;
    
    -- 曜日に応じたレートカラム決定
    rate_column := CASE day_of_week
        WHEN 1 THEN 'monday_rate'
        WHEN 2 THEN 'tuesday_rate'
        WHEN 3 THEN 'wednesday_rate'
        WHEN 4 THEN 'thursday_rate'
        WHEN 5 THEN 'friday_rate'
    END;
    
    RETURN QUERY
    EXECUTE format('
        SELECT 
            un.user_id,
            un.id as user_nft_id,
            un.nft_id,
            LEAST(
                un.purchase_price * gwr.%I,
                un.purchase_price * n.daily_rate_limit
            ) as reward_amount,
            format(''Date: %s, Rate: %s%%, NFT: %s, Price: $%s'', 
                $1, 
                ROUND(gwr.%I * 100, 2),
                n.name,
                un.purchase_price
            ) as calculation_details
        FROM user_nfts un
        JOIN nfts n ON un.nft_id = n.id
        JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
        JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
        WHERE gwr.week_start_date <= $1 
        AND gwr.week_end_date >= $1
        AND un.is_active = true
        AND un.purchase_date <= $1
    ', rate_column, rate_column) 
    USING p_date;
END;
$$ LANGUAGE plpgsql;

-- 3. get_system_status関数を改良
DROP FUNCTION IF EXISTS get_system_status();

CREATE OR REPLACE FUNCTION get_system_status()
RETURNS TABLE(
    metric_name TEXT,
    metric_value TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 'Total Users'::TEXT, COUNT(*)::TEXT FROM users WHERE is_admin = false
    UNION ALL
    SELECT 'Total NFTs'::TEXT, COUNT(*)::TEXT FROM nfts WHERE is_active = true
    UNION ALL
    SELECT 'Active User NFTs'::TEXT, COUNT(*)::TEXT FROM user_nfts WHERE is_active = true
    UNION ALL
    SELECT 'Total Investment'::TEXT, COALESCE(SUM(current_investment), 0)::TEXT FROM user_nfts WHERE is_active = true
    UNION ALL
    SELECT 'Total Groups'::TEXT, COUNT(*)::TEXT FROM daily_rate_groups
    UNION ALL
    SELECT 'Current Week Rates'::TEXT, COUNT(*)::TEXT FROM group_weekly_rates 
    WHERE week_start_date = date_trunc('week', CURRENT_DATE)::DATE
    UNION ALL
    SELECT 'Backup Records'::TEXT, COUNT(*)::TEXT FROM group_weekly_rates_backup
    UNION ALL
    SELECT 'Today Rewards'::TEXT, COALESCE(COUNT(*), 0)::TEXT FROM daily_rewards WHERE reward_date = CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

-- 4. get_weekly_rates_with_groups関数を追加
CREATE OR REPLACE FUNCTION get_weekly_rates_with_groups()
RETURNS TABLE(
    id UUID,
    week_start_date DATE,
    week_end_date DATE,
    weekly_rate NUMERIC,
    monday_rate NUMERIC,
    tuesday_rate NUMERIC,
    wednesday_rate NUMERIC,
    thursday_rate NUMERIC,
    friday_rate NUMERIC,
    group_name TEXT,
    distribution_method TEXT,
    has_backup BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwr.id,
        gwr.week_start_date,
        gwr.week_end_date,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        drg.group_name::TEXT,
        gwr.distribution_method::TEXT,
        EXISTS(
            SELECT 1 FROM group_weekly_rates_backup gwrb 
            WHERE gwrb.week_start_date = gwr.week_start_date 
            AND gwrb.group_id = gwr.group_id
        ) as has_backup
    FROM group_weekly_rates gwr
    JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit;
END;
$$ LANGUAGE plpgsql;

-- 5. テスト実行
SELECT 'Testing fixed functions...' as status;

-- システム状況確認
SELECT * FROM get_system_status();

-- 利用可能グループ確認
SELECT * FROM show_available_groups();

-- 週間レートとグループの確認
SELECT * FROM get_weekly_rates_with_groups();

SELECT 'NFT-Group relationship fixed successfully!' as status;
