-- 日利計算関数の最終修正

-- 1. 既存の関数を削除
DROP FUNCTION IF EXISTS calculate_daily_rewards(date);
DROP FUNCTION IF EXISTS execute_daily_calculation(date);

-- 2. 日利計算関数を作成
CREATE OR REPLACE FUNCTION calculate_daily_rewards(target_date DATE)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    processed_count INTEGER,
    total_amount NUMERIC
) AS $$
DECLARE
    week_start_monday DATE;
    day_of_week INTEGER;
    processed_count_var INTEGER := 0;
    total_amount_var NUMERIC := 0;
BEGIN
    -- 対象日の週の月曜日を計算
    week_start_monday := target_date - (EXTRACT(DOW FROM target_date)::INTEGER - 1);
    
    -- 曜日を取得（1=月曜日, 2=火曜日, ..., 5=金曜日）
    day_of_week := EXTRACT(DOW FROM target_date)::INTEGER;
    
    -- 土日は計算しない
    IF day_of_week = 0 OR day_of_week = 6 THEN
        RETURN QUERY SELECT 
            false as success,
            '土日は日利計算を行いません' as message,
            0 as processed_count,
            0::NUMERIC as total_amount;
        RETURN;
    END IF;
    
    -- 既存の報酬データを削除
    DELETE FROM daily_rewards WHERE reward_date = target_date;
    
    -- 日利計算と挿入
    WITH daily_rates AS (
        SELECT 
            gwr.group_name,
            CASE day_of_week
                WHEN 1 THEN gwr.monday_rate
                WHEN 2 THEN gwr.tuesday_rate
                WHEN 3 THEN gwr.wednesday_rate
                WHEN 4 THEN gwr.thursday_rate
                WHEN 5 THEN gwr.friday_rate
                ELSE 0
            END as daily_rate,
            gwr.weekly_rate
        FROM group_weekly_rates gwr
        WHERE gwr.week_start_date = week_start_monday
    ),
    nft_calculations AS (
        SELECT 
            un.id as user_nft_id,
            un.user_id,
            un.nft_id,
            un.purchase_price,
            n.daily_rate_limit,
            drg.group_name,
            dr.daily_rate,
            dr.weekly_rate,
            LEAST(un.purchase_price * dr.daily_rate, n.daily_rate_limit) as calculated_reward
        FROM user_nfts un
        JOIN nfts n ON un.nft_id = n.id
        JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
        JOIN daily_rates dr ON drg.group_name = dr.group_name
        WHERE un.is_active = true
        AND (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date <= target_date
        AND dr.daily_rate > 0
    )
    INSERT INTO daily_rewards (
        user_nft_id,
        user_id,
        nft_id,
        reward_amount,
        reward_date,
        daily_rate,
        weekly_rate,
        is_claimed,
        created_at,
        updated_at
    )
    SELECT 
        nc.user_nft_id,
        nc.user_id,
        nc.nft_id,
        nc.calculated_reward,
        target_date,
        nc.daily_rate,
        nc.weekly_rate,
        false,
        NOW(),
        NOW()
    FROM nft_calculations nc
    WHERE nc.calculated_reward > 0;
    
    -- 処理結果を取得
    GET DIAGNOSTICS processed_count_var = ROW_COUNT;
    
    SELECT COALESCE(SUM(reward_amount), 0) INTO total_amount_var
    FROM daily_rewards
    WHERE reward_date = target_date;
    
    RETURN QUERY SELECT 
        true as success,
        format('%s の日利計算完了: %s件、合計$%s', target_date, processed_count_var, total_amount_var) as message,
        processed_count_var as processed_count,
        total_amount_var as total_amount;
END;
$$ LANGUAGE plpgsql;

-- 3. 実行用関数を作成
CREATE OR REPLACE FUNCTION execute_daily_calculation(target_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    processed_count INTEGER,
    total_amount NUMERIC
) AS $$
BEGIN
    RETURN QUERY SELECT * FROM calculate_daily_rewards(target_date);
END;
$$ LANGUAGE plpgsql;

SELECT '✅ 日利計算関数の最終修正完了' as status;
