-- 緊急：日利計算システムの完全修正

-- 1. 現在の週利設定状況を確認
SELECT 
  'Week Rates Status' as check_type,
  COUNT(*) as total_rates,
  MIN(week_start_date) as earliest_week,
  MAX(week_start_date) as latest_week
FROM group_weekly_rates;

-- 2. 今週の週利設定を強制作成
DO $$
DECLARE
  current_week_start DATE;
  rates_exist INTEGER;
BEGIN
  -- 今週の月曜日を計算
  current_week_start := (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day')::DATE;
  
  -- 既存の設定をチェック
  SELECT COUNT(*) INTO rates_exist
  FROM group_weekly_rates
  WHERE week_start_date = current_week_start;
  
  IF rates_exist = 0 THEN
    RAISE NOTICE '今週の週利設定を作成します: %', current_week_start;
    
    -- 各グループに週利設定を作成
    INSERT INTO group_weekly_rates (
      group_id,
      week_start_date,
      week_end_date,
      week_number,
      weekly_rate,
      monday_rate,
      tuesday_rate,
      wednesday_rate,
      thursday_rate,
      friday_rate,
      distribution_method,
      created_at
    )
    SELECT 
      drg.id,
      current_week_start,
      current_week_start + INTERVAL '6 days',
      EXTRACT(WEEK FROM current_week_start),
      0.026, -- 2.6%
      0.005, -- 0.5%
      0.006, -- 0.6%
      0.005, -- 0.5%
      0.005, -- 0.5%
      0.005, -- 0.5%
      'EMERGENCY_CREATED',
      NOW()
    FROM daily_rate_groups drg;
    
    RAISE NOTICE '今週の週利設定を作成しました';
  ELSE
    RAISE NOTICE '今週の週利設定は既に存在します: % 件', rates_exist;
  END IF;
END $$;

-- 3. 過去1週間の週利設定も作成
DO $$
DECLARE
  last_week_start DATE;
  rates_exist INTEGER;
BEGIN
  -- 先週の月曜日を計算
  last_week_start := (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day' - INTERVAL '7 days')::DATE;
  
  -- 既存の設定をチェック
  SELECT COUNT(*) INTO rates_exist
  FROM group_weekly_rates
  WHERE week_start_date = last_week_start;
  
  IF rates_exist = 0 THEN
    RAISE NOTICE '先週の週利設定を作成します: %', last_week_start;
    
    -- 各グループに週利設定を作成
    INSERT INTO group_weekly_rates (
      group_id,
      week_start_date,
      week_end_date,
      week_number,
      weekly_rate,
      monday_rate,
      tuesday_rate,
      wednesday_rate,
      thursday_rate,
      friday_rate,
      distribution_method,
      created_at
    )
    SELECT 
      drg.id,
      last_week_start,
      last_week_start + INTERVAL '6 days',
      EXTRACT(WEEK FROM last_week_start),
      0.026, -- 2.6%
      0.005, -- 0.5%
      0.006, -- 0.6%
      0.005, -- 0.5%
      0.005, -- 0.5%
      0.005, -- 0.5%
      'EMERGENCY_CREATED',
      NOW()
    FROM daily_rate_groups drg;
    
    RAISE NOTICE '先週の週利設定を作成しました';
  END IF;
END $$;

-- 4. 日利計算関数を再作成（エラーハンドリング強化）
CREATE OR REPLACE FUNCTION calculate_daily_rewards_emergency(
  p_calculation_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE(
  message TEXT,
  processed_count INTEGER,
  total_rewards DECIMAL,
  error_details TEXT
) AS $$
DECLARE
  calc_date DATE := p_calculation_date;
  day_of_week INTEGER;
  processed_count INTEGER := 0;
  total_amount DECIMAL := 0;
  error_msg TEXT := NULL;
  debug_info TEXT := '';
BEGIN
  -- 曜日を取得
  day_of_week := EXTRACT(DOW FROM calc_date);
  
  -- 平日チェック
  IF day_of_week NOT BETWEEN 1 AND 5 THEN
    RETURN QUERY SELECT 
      format('土日は処理しません: %s (曜日: %s)', calc_date, day_of_week)::TEXT,
      0::INTEGER,
      0::DECIMAL,
      NULL::TEXT;
    RETURN;
  END IF;

  BEGIN
    -- デバッグ情報
    debug_info := format('日付: %s, 曜日: %s', calc_date, day_of_week);
    
    -- 既存レコード削除
    DELETE FROM daily_rewards WHERE reward_date = calc_date;
    
    -- 週利設定の存在確認
    IF NOT EXISTS (
      SELECT 1 FROM group_weekly_rates gwr
      WHERE calc_date BETWEEN gwr.week_start_date::DATE AND gwr.week_end_date::DATE
    ) THEN
      error_msg := format('週利設定が見つかりません: %s', calc_date);
      RAISE EXCEPTION '%', error_msg;
    END IF;
    
    -- 日利計算実行
    WITH calculation_data AS (
      SELECT 
        un.user_id,
        un.nft_id,
        un.current_investment,
        n.name as nft_name,
        n.daily_rate_limit,
        CASE 
          WHEN day_of_week = 1 THEN gwr.monday_rate
          WHEN day_of_week = 2 THEN gwr.tuesday_rate
          WHEN day_of_week = 3 THEN gwr.wednesday_rate
          WHEN day_of_week = 4 THEN gwr.thursday_rate
          WHEN day_of_week = 5 THEN gwr.friday_rate
          ELSE 0
        END as daily_rate
      FROM user_nfts un
      JOIN nfts n ON un.nft_id = n.id
      JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
      JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
      WHERE un.is_active = true
        AND un.current_investment > 0
        AND n.is_active = true
        AND calc_date BETWEEN gwr.week_start_date::DATE AND gwr.week_end_date::DATE
    )
    INSERT INTO daily_rewards (
      user_id,
      nft_id,
      reward_date,
      purchase_amount,
      daily_rate,
      reward_amount,
      is_claimed,
      created_at
    )
    SELECT 
      user_id,
      nft_id,
      calc_date,
      current_investment,
      LEAST(daily_rate, daily_rate_limit),
      current_investment * LEAST(daily_rate, daily_rate_limit),
      false,
      NOW()
    FROM calculation_data
    WHERE daily_rate > 0;
    
    -- 処理件数取得
    GET DIAGNOSTICS processed_count = ROW_COUNT;
    
    -- 合計金額計算
    SELECT COALESCE(SUM(reward_amount), 0) INTO total_amount
    FROM daily_rewards 
    WHERE reward_date = calc_date;
    
  EXCEPTION WHEN OTHERS THEN
    error_msg := SQLERRM;
    processed_count := 0;
    total_amount := 0;
  END;
  
  RETURN QUERY SELECT 
    CASE 
      WHEN error_msg IS NOT NULL THEN format('エラー: %s (%s)', error_msg, debug_info)
      WHEN processed_count > 0 THEN format('成功: %s件処理, 合計$%.2f (%s)', processed_count, total_amount, debug_info)
      ELSE format('処理対象なし (%s)', debug_info)
    END::TEXT,
    processed_count::INTEGER,
    total_amount::DECIMAL,
    error_msg::TEXT;
END;
$$ LANGUAGE plpgsql;

-- 5. 緊急日利計算実行
SELECT 'Starting emergency daily calculation...' as status;

-- 今日の計算
SELECT * FROM calculate_daily_rewards_emergency(CURRENT_DATE);

-- 過去5営業日の計算
DO $$
DECLARE
  calc_date DATE;
  day_of_week INTEGER;
  result_record RECORD;
  business_days_processed INTEGER := 0;
BEGIN
  RAISE NOTICE '過去営業日の日利計算を開始';
  
  FOR i IN 1..10 LOOP -- 最大10日前まで遡る
    calc_date := CURRENT_DATE - i;
    day_of_week := EXTRACT(DOW FROM calc_date);
    
    -- 平日のみ処理
    IF day_of_week BETWEEN 1 AND 5 THEN
      FOR result_record IN 
        SELECT * FROM calculate_daily_rewards_emergency(calc_date)
      LOOP
        RAISE NOTICE '% - %', calc_date, result_record.message;
        
        IF result_record.error_details IS NOT NULL THEN
          RAISE NOTICE 'エラー詳細: %', result_record.error_details;
        END IF;
      END LOOP;
      
      business_days_processed := business_days_processed + 1;
      
      -- 5営業日処理したら終了
      IF business_days_processed >= 5 THEN
        EXIT;
      END IF;
    END IF;
  END LOOP;
  
  RAISE NOTICE '営業日処理完了: %日', business_days_processed;
END $$;

-- 6. 最終結果確認
SELECT 
  'Final Results' as result_type,
  COUNT(*) as total_records,
  COUNT(DISTINCT user_id) as unique_users,
  COUNT(DISTINCT reward_date) as unique_dates,
  SUM(reward_amount) as total_amount,
  MIN(reward_date) as earliest_date,
  MAX(reward_date) as latest_date
FROM daily_rewards;

-- 7. 上位ユーザーの報酬状況
SELECT 
  'Top User Rewards' as check_type,
  COALESCE(u.name, u.email) as user_name,
  COUNT(dr.id) as reward_count,
  SUM(dr.reward_amount) as total_rewards
FROM daily_rewards dr
JOIN users u ON dr.user_id = u.id
WHERE dr.is_claimed = false
GROUP BY u.id, u.name, u.email
ORDER BY total_rewards DESC
LIMIT 10;

SELECT 'Emergency daily calculation completed' as final_status;
