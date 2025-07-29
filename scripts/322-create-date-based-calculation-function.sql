-- 日付ベースでの日利計算関数を作成
CREATE OR REPLACE FUNCTION calculate_daily_rewards_by_date(
  start_date DATE,
  end_date DATE
) RETURNS TABLE(
  message TEXT,
  processed_users INTEGER,
  total_rewards DECIMAL
) AS $$
DECLARE
  current_date DATE;
  processed_count INTEGER := 0;
  total_amount DECIMAL := 0;
BEGIN
  -- 日付範囲をループ
  current_date := start_date;
  
  WHILE current_date <= end_date LOOP
    -- 平日のみ処理（月〜金）
    IF EXTRACT(DOW FROM current_date) BETWEEN 1 AND 5 THEN
      -- その日の日利計算を実行
      WITH daily_calculation AS (
        SELECT 
          un.user_id,
          un.nft_id,
          un.purchase_amount,
          CASE 
            WHEN current_date = start_date THEN COALESCE(gwr.monday_rate, 0)
            WHEN current_date = start_date + INTERVAL '1 day' THEN COALESCE(gwr.tuesday_rate, 0)
            WHEN current_date = start_date + INTERVAL '2 days' THEN COALESCE(gwr.wednesday_rate, 0)
            WHEN current_date = start_date + INTERVAL '3 days' THEN COALESCE(gwr.thursday_rate, 0)
            WHEN current_date = start_date + INTERVAL '4 days' THEN COALESCE(gwr.friday_rate, 0)
            ELSE 0
          END as daily_rate,
          n.daily_rate_limit
        FROM user_nfts un
        JOIN nfts n ON un.nft_id = n.id
        JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
        LEFT JOIN group_weekly_rates gwr ON drg.id = gwr.group_id 
          AND gwr.week_start_date = start_date
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
        current_date,
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
      
      -- 合計金額を計算
      SELECT COALESCE(SUM(reward_amount), 0) INTO total_amount
      FROM daily_rewards 
      WHERE reward_date = current_date;
      
    END IF;
    
    current_date := current_date + INTERVAL '1 day';
  END LOOP;
  
  RETURN QUERY SELECT 
    format('期間 %s～%s の日利計算が完了しました', start_date, end_date)::TEXT,
    processed_count::INTEGER,
    total_amount::DECIMAL;
END;
$$ LANGUAGE plpgsql;
