-- NFTとグループの関連エラーを修正

-- 1. まず実際のnftsテーブル構造を確認
SELECT 
    '📋 NFTテーブル構造確認' as section,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'nfts' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. daily_rate_groupsテーブル構造確認
SELECT 
    '📊 日利グループテーブル構造確認' as section,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'daily_rate_groups' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. show_available_groups関数を正しい関連で修正
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
        drg.group_name,
        COUNT(n.id) as nft_count,
        COALESCE(SUM(n.price), 0) as total_investment
    FROM daily_rate_groups drg
    LEFT JOIN nfts n ON n.daily_rate_limit = drg.daily_rate_limit
    GROUP BY drg.id, drg.group_name
    ORDER BY drg.group_name;
END;
$$ LANGUAGE plpgsql;

-- 4. get_weekly_rates_with_groups関数も修正
DROP FUNCTION IF EXISTS get_weekly_rates_with_groups();

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
        drg.group_name,
        COALESCE(gwr.distribution_method, 'random') as distribution_method,
        EXISTS(
            SELECT 1 FROM group_weekly_rates_backup gwrb 
            WHERE gwrb.week_start_date = gwr.week_start_date
        ) as has_backup
    FROM group_weekly_rates gwr
    JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    ORDER BY gwr.week_start_date DESC, drg.group_name;
END;
$$ LANGUAGE plpgsql;

-- 5. 日利計算関数も修正
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

-- 6. 権限設定
GRANT EXECUTE ON FUNCTION show_available_groups() TO authenticated;
GRANT EXECUTE ON FUNCTION get_weekly_rates_with_groups() TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_daily_rewards_for_date(DATE) TO authenticated;

-- 7. NFTとグループの関連確認
SELECT 
    '🔗 NFT-グループ関連確認' as section,
    n.name,
    n.daily_rate_limit,
    drg.group_name,
    drg.daily_rate_limit as group_limit
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
WHERE n.is_active = true
ORDER BY n.daily_rate_limit
LIMIT 10;

SELECT 'NFT-Group relationship fixed successfully!' as status;
