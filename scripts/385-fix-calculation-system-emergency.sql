-- 緊急修正: 正しい週利配分システムの実装

-- 1. 現在使用されている間違った関数を特定・削除
DROP FUNCTION IF EXISTS calculate_daily_rewards_batch();
DROP FUNCTION IF EXISTS calculate_daily_rewards();
DROP FUNCTION IF EXISTS calculate_daily_rewards_fixed(DATE);

-- 2. 今日の間違った計算結果を全削除
DELETE FROM daily_rewards WHERE reward_date = CURRENT_DATE;

-- 3. 正しい週利配分計算関数を作成
CREATE OR REPLACE FUNCTION calculate_daily_rewards_with_weekly_rates()
RETURNS TABLE(
    processed_count INTEGER,
    total_rewards NUMERIC,
    calculation_date DATE,
    error_message TEXT
) AS $$
DECLARE
    day_of_week INTEGER;
    week_start DATE;
    processed INTEGER := 0;
    total_amount NUMERIC := 0;
    current_date DATE := CURRENT_DATE;
BEGIN
    -- 曜日を取得（0=日曜, 1=月曜, ..., 5=金曜, 6=土曜）
    day_of_week := EXTRACT(DOW FROM current_date);
    
    -- 平日以外は計算しない
    IF day_of_week NOT IN (1, 2, 3, 4, 5) THEN
        RETURN QUERY SELECT 0, 0::NUMERIC, current_date, '土日は計算を実行しません'::TEXT;
        RETURN;
    END IF;
    
    -- その週の月曜日を計算
    week_start := current_date - (day_of_week - 1) * INTERVAL '1 day';
    
    -- 週利設定があるかチェック
    IF NOT EXISTS (
        SELECT 1 FROM group_weekly_rates 
        WHERE week_start_date = week_start
    ) THEN
        RETURN QUERY SELECT 0, 0::NUMERIC, current_date, ('週利設定がありません: ' || week_start::TEXT)::TEXT;
        RETURN;
    END IF;
    
    -- 各ユーザーのNFTに対して計算実行
    INSERT INTO daily_rewards (
        user_nft_id,
        reward_date,
        reward_amount,
        daily_rate,
        investment_amount,
        is_claimed,
        created_at
    )
    SELECT 
        un.id,
        current_date,
        n.price * CASE day_of_week
            WHEN 1 THEN LEAST(COALESCE(gwr.monday_rate, 0), n.daily_rate_limit / 100.0)
            WHEN 2 THEN LEAST(COALESCE(gwr.tuesday_rate, 0), n.daily_rate_limit / 100.0)
            WHEN 3 THEN LEAST(COALESCE(gwr.wednesday_rate, 0), n.daily_rate_limit / 100.0)
            WHEN 4 THEN LEAST(COALESCE(gwr.thursday_rate, 0), n.daily_rate_limit / 100.0)
            WHEN 5 THEN LEAST(COALESCE(gwr.friday_rate, 0), n.daily_rate_limit / 100.0)
        END,
        CASE day_of_week
            WHEN 1 THEN LEAST(COALESCE(gwr.monday_rate, 0), n.daily_rate_limit / 100.0)
            WHEN 2 THEN LEAST(COALESCE(gwr.tuesday_rate, 0), n.daily_rate_limit / 100.0)
            WHEN 3 THEN LEAST(COALESCE(gwr.wednesday_rate, 0), n.daily_rate_limit / 100.0)
            WHEN 4 THEN LEAST(COALESCE(gwr.thursday_rate, 0), n.daily_rate_limit / 100.0)
            WHEN 5 THEN LEAST(COALESCE(gwr.friday_rate, 0), n.daily_rate_limit / 100.0)
        END,
        n.price,
        false,
        NOW()
    FROM users u
    JOIN user_nfts un ON u.id = un.user_id
    JOIN nfts n ON un.nft_id = n.id
    JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
    JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
    WHERE un.is_active = true
    AND gwr.week_start_date = week_start
    AND CASE day_of_week
        WHEN 1 THEN gwr.monday_rate
        WHEN 2 THEN gwr.tuesday_rate
        WHEN 3 THEN gwr.wednesday_rate
        WHEN 4 THEN gwr.thursday_rate
        WHEN 5 THEN gwr.friday_rate
    END IS NOT NULL
    AND CASE day_of_week
        WHEN 1 THEN gwr.monday_rate
        WHEN 2 THEN gwr.tuesday_rate
        WHEN 3 THEN gwr.wednesday_rate
        WHEN 4 THEN gwr.thursday_rate
        WHEN 5 THEN gwr.friday_rate
    END > 0;
    
    -- 処理結果を取得
    GET DIAGNOSTICS processed = ROW_COUNT;
    
    SELECT COALESCE(SUM(reward_amount), 0) INTO total_amount
    FROM daily_rewards 
    WHERE reward_date = current_date;
    
    -- user_nftsのtotal_earnedを更新
    UPDATE user_nfts 
    SET total_earned = (
        SELECT COALESCE(SUM(dr.reward_amount), 0)
        FROM daily_rewards dr
        WHERE dr.user_nft_id = user_nfts.id
    ),
    updated_at = NOW()
    WHERE is_active = true;
    
    RETURN QUERY SELECT processed, total_amount, current_date, NULL::TEXT;
END;
$$ LANGUAGE plpgsql;

-- 4. システム状態の確認
SELECT 
    '✅ 修正完了' as info,
    '固定0.5%計算を廃止' as 変更1,
    '週利配分システムを正しく実装' as 変更2,
    '今日は週利設定がないため計算実行されない' as 結果;
