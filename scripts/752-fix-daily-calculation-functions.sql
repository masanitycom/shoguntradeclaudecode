-- 日利計算関数の修正と作成

-- 1. 既存の問題のある関数を削除
DROP FUNCTION IF EXISTS calculate_daily_rewards(date);
DROP FUNCTION IF EXISTS calculate_daily_rewards_for_date(date);
DROP FUNCTION IF EXISTS execute_daily_calculation(date);
DROP FUNCTION IF EXISTS force_daily_calculation();

-- 2. 基本的な日利計算関数を作成
CREATE OR REPLACE FUNCTION calculate_daily_rewards(target_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    processed_count INTEGER,
    total_amount NUMERIC
) AS $$
DECLARE
    day_of_week INTEGER;
    week_start_monday DATE;
    calculation_count INTEGER := 0;
    total_rewards NUMERIC := 0;
    existing_count INTEGER := 0;
BEGIN
    -- 曜日を取得（0=日曜, 1=月曜...）
    day_of_week := EXTRACT(DOW FROM target_date);
    
    -- 土日は計算しない
    IF day_of_week IN (0, 6) THEN
        RETURN QUERY SELECT false, 
                           FORMAT('土日は日利計算を行いません: %s', target_date), 
                           0, 
                           0::NUMERIC;
        RETURN;
    END IF;
    
    -- 週の開始日（月曜日）を計算
    week_start_monday := target_date - (day_of_week - 1);
    
    RAISE NOTICE '日利計算開始: % (曜日: %, 週開始: %)', target_date, day_of_week, week_start_monday;
    
    -- 既存の計算をチェック
    SELECT COUNT(*) INTO existing_count
    FROM daily_rewards 
    WHERE reward_date = target_date;
    
    IF existing_count > 0 THEN
        SELECT SUM(reward_amount) INTO total_rewards
        FROM daily_rewards 
        WHERE reward_date = target_date;
        
        RETURN QUERY SELECT true, 
                           FORMAT('既に計算済み: %s件、合計$%s', existing_count, total_rewards), 
                           existing_count, 
                           total_rewards;
        RETURN;
    END IF;
    
    -- 日利計算を実行
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
    
    GET DIAGNOSTICS calculation_count = ROW_COUNT;
    
    -- 合計金額を計算
    SELECT COALESCE(SUM(reward_amount), 0) INTO total_rewards
    FROM daily_rewards 
    WHERE reward_date = target_date;
    
    -- user_nftsテーブルのtotal_earnedも更新
    UPDATE user_nfts 
    SET total_earned = total_earned + dr.reward_amount,
        updated_at = NOW()
    FROM daily_rewards dr
    WHERE user_nfts.id = dr.user_nft_id
    AND dr.reward_date = target_date;
    
    RAISE NOTICE '日利計算完了: %件の報酬を計算、合計$%', calculation_count, total_rewards;
    
    RETURN QUERY SELECT true, 
                        FORMAT('%s の日利計算完了: %s件、合計$%s', target_date, calculation_count, total_rewards),
                        calculation_count,
                        total_rewards;
END;
$$ LANGUAGE plpgsql;

-- 3. 管理画面用の統計取得関数
CREATE OR REPLACE FUNCTION get_daily_calculation_stats(target_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE(
    reward_date DATE,
    total_rewards INTEGER,
    total_amount NUMERIC,
    avg_amount NUMERIC,
    unique_users INTEGER,
    group_breakdown JSONB
) AS $$
BEGIN
    RETURN QUERY
    WITH group_stats AS (
        SELECT 
            dr.reward_date,
            drg.group_name,
            COUNT(dr.id) as group_count,
            SUM(dr.reward_amount) as group_total
        FROM daily_rewards dr
        JOIN user_nfts un ON dr.user_nft_id = un.id
        JOIN nfts n ON un.nft_id = n.id
        JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
        WHERE dr.reward_date = target_date
        GROUP BY dr.reward_date, drg.group_name
    )
    SELECT 
        dr.reward_date,
        COUNT(dr.id)::INTEGER as total_rewards,
        SUM(dr.reward_amount) as total_amount,
        AVG(dr.reward_amount) as avg_amount,
        COUNT(DISTINCT dr.user_id)::INTEGER as unique_users,
        COALESCE(
            jsonb_object_agg(
                gs.group_name, 
                jsonb_build_object(
                    'count', gs.group_count,
                    'total', gs.group_total
                )
            ), 
            '{}'::jsonb
        ) as group_breakdown
    FROM daily_rewards dr
    LEFT JOIN group_stats gs ON dr.reward_date = gs.reward_date
    WHERE dr.reward_date = target_date
    GROUP BY dr.reward_date;
END;
$$ LANGUAGE plpgsql;

-- 4. ユーザーダッシュボード用の関数
CREATE OR REPLACE FUNCTION get_user_daily_rewards(p_user_id UUID, target_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE(
    nft_name TEXT,
    purchase_price NUMERIC,
    daily_rate NUMERIC,
    reward_amount NUMERIC,
    is_claimed BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        n.name as nft_name,
        un.purchase_price,
        dr.daily_rate,
        dr.reward_amount,
        dr.is_claimed
    FROM daily_rewards dr
    JOIN user_nfts un ON dr.user_nft_id = un.id
    JOIN nfts n ON un.nft_id = n.id
    WHERE dr.user_id = p_user_id
    AND dr.reward_date = target_date
    ORDER BY dr.reward_amount DESC;
END;
$$ LANGUAGE plpgsql;

SELECT '✅ 日利計算関数の修正完了' as status;
