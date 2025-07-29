-- 日利計算関数を修正（正しいカラム名を使用）

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
  daily_processed INTEGER;
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
          un.current_investment,
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
          AND calc_date BETWEEN gwr.week_start_date::date AND gwr.week_end_date::date
        WHERE un.is_active = true
          AND un.current_investment > 0
          AND un.total_earned < un.max_earning
      ),
      reward_calculation AS (
        SELECT 
          user_id,
          nft_id,
          current_investment,
          LEAST(daily_rate / 100.0, daily_rate_limit) as effective_rate,
          current_investment * LEAST(daily_rate / 100.0, daily_rate_limit) as reward_amount
        FROM daily_calculation
        WHERE daily_rate > 0
      )
      INSERT INTO daily_rewards (
        user_id,
        nft_id,
        reward_date,
        investment_amount,
        daily_rate,
        reward_amount,
        created_at
      )
      SELECT 
        user_id,
        nft_id,
        calc_date,
        current_investment,
        effective_rate,
        reward_amount,
        NOW()
      FROM reward_calculation
      ON CONFLICT (user_id, nft_id, reward_date) DO UPDATE SET
        investment_amount = EXCLUDED.investment_amount,
        daily_rate = EXCLUDED.daily_rate,
        reward_amount = EXCLUDED.reward_amount,
        updated_at = NOW();
      
      -- その日の処理件数を取得
      GET DIAGNOSTICS daily_processed = ROW_COUNT;
      processed_count := processed_count + daily_processed;
      
      -- user_nfts の total_earned を更新
      UPDATE user_nfts 
      SET 
        total_earned = total_earned + (
          SELECT COALESCE(SUM(reward_amount), 0)
          FROM daily_rewards dr
          WHERE dr.user_id = user_nfts.user_id 
            AND dr.nft_id = user_nfts.nft_id
            AND dr.reward_date = calc_date
        ),
        updated_at = NOW()
      WHERE EXISTS (
        SELECT 1 FROM daily_rewards dr
        WHERE dr.user_id = user_nfts.user_id 
          AND dr.nft_id = user_nfts.nft_id
          AND dr.reward_date = calc_date
      );
      
      -- 300%達成したNFTを非アクティブ化
      UPDATE user_nfts 
      SET 
        is_active = false,
        completion_date = calc_date,
        updated_at = NOW()
      WHERE total_earned >= max_earning 
        AND is_active = true;
      
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

-- 関数のテスト実行
SELECT '日利計算関数を修正しました（user_nfts の正しいカラム名を使用）' as status;

-- 関数の存在確認
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name = 'calculate_daily_rewards_by_date';
