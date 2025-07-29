-- 日利計算関数を作成（週利管理画面用）

CREATE OR REPLACE FUNCTION calculate_daily_rewards_by_date(
  start_date DATE,
  end_date DATE
) RETURNS TABLE(
  message TEXT,
  processed_users INTEGER,
  total_rewards DECIMAL
) AS $$
DECLARE
  calc_date DATE;
  processed_count INTEGER := 0;
  total_amount DECIMAL := 0;
  day_of_week INTEGER;
BEGIN
  -- 日付範囲をループ
  calc_date := start_date;
  
  WHILE calc_date <= end_date LOOP
    -- 曜日を取得（0=日曜、1=月曜、...、6=土曜）
    day_of_week := EXTRACT(DOW FROM calc_date);
    
    -- 平日のみ処理（月〜金：1-5）
    IF day_of_week BETWEEN 1 AND 5 THEN
      -- その日の日利計算を実行
      WITH daily_calculation AS (
        SELECT 
          un.user_id,
          un.nft_id,
          un.purchase_amount,
          CASE 
            WHEN day_of_week = 1 THEN COALESCE(gwr.monday_rate, 0)
            WHEN day_of_week = 2 THEN COALESCE(gwr.tuesday_rate, 0)
            WHEN day_of_week = 3 THEN COALESCE(gwr.wednesday_rate, 0)
            WHEN day_of_week = 4 THEN COALESCE(gwr.thursday_rate, 0)
            WHEN day_of_week = 5 THEN COALESCE(gwr.friday_rate, 0)
            ELSE 0
          END as daily_rate,
          n.daily_rate_limit
        FROM user_nfts un
        JOIN nfts n ON un.nft_id = n.id
        JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
        LEFT JOIN group_weekly_rates gwr ON drg.id = gwr.group_id 
          AND calc_date BETWEEN gwr.week_start_date AND gwr.week_end_date
        WHERE un.is_active = true
          AND un.purchase_amount > 0
      ),
      reward_calculation AS (
        SELECT 
          user_id,
          nft_id,
          purchase_amount,
          LEAST(daily_rate / 100.0, daily_rate_limit) as effective_rate,
          purchase_amount * LEAST(daily_rate / 100.0, daily_rate_limit) as reward_amount
        FROM daily_calculation
        WHERE daily_rate > 0
      )
      INSERT INTO daily_rewards (
        user_id,
        nft_id,
        reward_date,
        purchase_amount,
        daily_rate,
        reward_amount,
        created_at
      )
      SELECT 
        user_id,
        nft_id,
        calc_date,
        purchase_amount,
        effective_rate,
        reward_amount,
        NOW()
      FROM reward_calculation
      ON CONFLICT (user_id, nft_id, reward_date) DO UPDATE SET
        purchase_amount = EXCLUDED.purchase_amount,
        daily_rate = EXCLUDED.daily_rate,
        reward_amount = EXCLUDED.reward_amount,
        updated_at = NOW();
      
      -- 処理件数を更新
      GET DIAGNOSTICS processed_count = ROW_COUNT;
      
    END IF;
    
    calc_date := calc_date + INTERVAL '1 day';
  END LOOP;
  
  -- 期間全体の合計金額を計算
  SELECT COALESCE(SUM(reward_amount), 0) INTO total_amount
  FROM daily_rewards 
  WHERE reward_date BETWEEN start_date AND end_date;
  
  RETURN QUERY SELECT 
    format('期間 %s～%s の日利計算が完了しました', start_date, end_date)::TEXT,
    processed_count::INTEGER,
    total_amount::DECIMAL;
END;
$$ LANGUAGE plpgsql;

-- 関数作成完了
SELECT '日利計算関数 calculate_daily_rewards_by_date を作成しました' as status;
