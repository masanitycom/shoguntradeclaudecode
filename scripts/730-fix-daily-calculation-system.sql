-- 🔧 日利計算システムの完全修復

-- 1. 既存の問題のある関数を削除
DROP FUNCTION IF EXISTS calculate_daily_rewards();
DROP FUNCTION IF EXISTS calculate_daily_rewards(DATE);
DROP FUNCTION IF EXISTS force_daily_calculation();

-- 2. 日利計算の基本関数を作成
CREATE OR REPLACE FUNCTION calculate_daily_rewards_for_date(target_date DATE)
RETURNS TABLE(
    user_id UUID,
    user_nft_id INTEGER,
    reward_amount DECIMAL,
    calculation_details TEXT
) AS $$
DECLARE
    day_of_week INTEGER;
    week_start_date DATE;
    calculation_count INTEGER := 0;
BEGIN
    -- 曜日を取得（0=日曜, 1=月曜...）
    day_of_week := EXTRACT(DOW FROM target_date);
    
    -- 土日は計算しない
    IF day_of_week IN (0, 6) THEN
        RAISE NOTICE '土日のため日利計算をスキップします: %', target_date;
        RETURN;
    END IF;
    
    -- 週の開始日（月曜日）を計算
    week_start_date := target_date - (day_of_week - 1);
    
    RAISE NOTICE '日利計算開始: % (曜日: %, 週開始: %)', target_date, day_of_week, week_start_date;
    
    -- 日利計算を実行
    RETURN QUERY
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
            END as daily_rate
        FROM group_weekly_rates gwr
        WHERE gwr.week_start_date = week_start_date
    ),
    nft_calculations AS (
        SELECT 
            un.user_id,
            un.id as user_nft_id,
            n.price,
            n.daily_rate_limit,
            drg.group_name,
            dr.daily_rate,
            LEAST(n.price * dr.daily_rate, n.daily_rate_limit) as calculated_reward
        FROM user_nfts un
        JOIN nfts n ON un.nft_id = n.id
        JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
        JOIN daily_rates dr ON drg.group_name = dr.group_name
        WHERE un.is_active = true
        AND dr.daily_rate > 0
    )
    SELECT 
        nc.user_id,
        nc.user_nft_id,
        nc.calculated_reward,
        FORMAT('NFT価格: $%s × 日利: %s%% = $%s (上限: $%s)', 
               nc.price, 
               (nc.daily_rate * 100)::TEXT, 
               nc.calculated_reward::TEXT,
               nc.daily_rate_limit::TEXT
        ) as calculation_details
    FROM nft_calculations nc
    WHERE nc.calculated_reward > 0;
    
    GET DIAGNOSTICS calculation_count = ROW_COUNT;
    RAISE NOTICE '日利計算完了: %件の報酬を計算', calculation_count;
END;
$$ LANGUAGE plpgsql;

-- 3. 日利計算実行＆保存関数
CREATE OR REPLACE FUNCTION execute_daily_calculation(target_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    processed_count INTEGER,
    total_amount DECIMAL
) AS $$
DECLARE
    calc_count INTEGER := 0;
    total_rewards DECIMAL := 0;
    day_of_week INTEGER;
BEGIN
    day_of_week := EXTRACT(DOW FROM target_date);
    
    -- 土日チェック
    IF day_of_week IN (0, 6) THEN
        RETURN QUERY SELECT false, '土日は日利計算を行いません', 0, 0::DECIMAL;
        RETURN;
    END IF;
    
    -- 既存の計算をチェック
    IF EXISTS (SELECT 1 FROM daily_rewards WHERE reward_date = target_date) THEN
        RETURN QUERY SELECT false, '既に計算済みです', 0, 0::DECIMAL;
        RETURN;
    END IF;
    
    -- 日利計算を実行して保存
    INSERT INTO daily_rewards (user_nft_id, reward_amount, reward_date, is_claimed, created_at, updated_at)
    SELECT 
        cdr.user_nft_id,
        cdr.reward_amount,
        target_date,
        false,
        NOW(),
        NOW()
    FROM calculate_daily_rewards_for_date(target_date) cdr;
    
    GET DIAGNOSTICS calc_count = ROW_COUNT;
    
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
    
    RETURN QUERY SELECT true, 
                        FORMAT('%s の日利計算完了: %s件、合計$%s', target_date, calc_count, total_rewards),
                        calc_count,
                        total_rewards;
END;
$$ LANGUAGE plpgsql;

-- 4. 手動実行用の簡単な関数
CREATE OR REPLACE FUNCTION force_daily_calculation()
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    processed_count INTEGER,
    total_amount DECIMAL
) AS $$
BEGIN
    RETURN QUERY SELECT * FROM execute_daily_calculation(CURRENT_DATE);
END;
$$ LANGUAGE plpgsql;

SELECT '🔧 日利計算システム修復完了' as status;
