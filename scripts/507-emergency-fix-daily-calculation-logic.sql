-- 緊急：日利計算ロジックの完全修正

-- 1. 現在の週利設定を確認
SELECT 
  'Current Week Rates Check' as check_type,
  gwr.*,
  drg.group_name
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE CURRENT_DATE BETWEEN gwr.week_start_date::DATE AND gwr.week_end_date::DATE
ORDER BY drg.daily_rate_limit;

-- 2. 日利計算関数を完全に修正
DROP FUNCTION IF EXISTS calculate_daily_rewards_batch(DATE);

CREATE OR REPLACE FUNCTION calculate_daily_rewards_batch(
  p_calculation_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE(
  message TEXT,
  processed_count INTEGER,
  total_rewards DECIMAL,
  completed_nfts INTEGER,
  error_message TEXT
) AS $$
DECLARE
  calc_date DATE := p_calculation_date;
  day_of_week INTEGER;
  processed_count INTEGER := 0;
  total_amount DECIMAL := 0;
  completed_count INTEGER := 0;
  error_msg TEXT := NULL;
  debug_info TEXT := '';
BEGIN
  -- 曜日を取得（0=日曜、1=月曜、...、6=土曜）
  day_of_week := EXTRACT(DOW FROM calc_date);
  
  -- 平日のみ処理（月〜金：1-5）
  IF day_of_week NOT BETWEEN 1 AND 5 THEN
    RETURN QUERY SELECT 
      '土日は日利計算を行いません'::TEXT,
      0::INTEGER,
      0::DECIMAL,
      0::INTEGER,
      NULL::TEXT;
    RETURN;
  END IF;

  BEGIN
    -- デバッグ情報を収集
    SELECT format('計算日: %s, 曜日: %s', calc_date, day_of_week) INTO debug_info;
    
    -- 今日の既存レコードを削除
    DELETE FROM daily_rewards WHERE reward_date = calc_date;
    
    -- 日利計算を実行（詳細なデバッグ付き）
    WITH week_rates_check AS (
      SELECT 
        gwr.group_id,
        gwr.week_start_date,
        gwr.week_end_date,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        drg.group_name,
        drg.daily_rate_limit
      FROM group_weekly_rates gwr
      JOIN daily_rate_groups drg ON gwr.group_id = drg.id
      WHERE calc_date BETWEEN gwr.week_start_date::DATE AND gwr.week_end_date::DATE
    ),
    user_nft_data AS (
      SELECT 
        un.user_id,
        un.nft_id,
        un.current_investment,
        n.name as nft_name,
        n.daily_rate_limit,
        wrc.group_id,
        wrc.group_name,
        CASE 
          WHEN day_of_week = 1 THEN wrc.monday_rate
          WHEN day_of_week = 2 THEN wrc.tuesday_rate
          WHEN day_of_week = 3 THEN wrc.wednesday_rate
          WHEN day_of_week = 4 THEN wrc.thursday_rate
          WHEN day_of_week = 5 THEN wrc.friday_rate
          ELSE 0
        END as daily_rate
      FROM user_nfts un
      JOIN nfts n ON un.nft_id = n.id
      JOIN week_rates_check wrc ON n.daily_rate_limit = wrc.daily_rate_limit
      WHERE un.is_active = true
        AND un.current_investment > 0
        AND n.is_active = true
    ),
    reward_calculation AS (
      SELECT 
        user_id,
        nft_id,
        current_investment,
        nft_name,
        daily_rate_limit,
        daily_rate,
        LEAST(daily_rate, daily_rate_limit) as effective_rate,
        current_investment * LEAST(daily_rate, daily_rate_limit) as reward_amount
      FROM user_nft_data
      WHERE daily_rate > 0
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
      effective_rate,
      reward_amount,
      false,
      NOW()
    FROM reward_calculation;
    
    -- 処理件数を取得
    GET DIAGNOSTICS processed_count = ROW_COUNT;
    
    -- 合計金額を計算
    SELECT COALESCE(SUM(reward_amount), 0) INTO total_amount
    FROM daily_rewards 
    WHERE reward_date = calc_date;
    
    -- 完了NFT数を計算（300%達成）
    SELECT COUNT(*) INTO completed_count
    FROM user_nfts un
    WHERE un.total_earned >= un.max_earning
      AND un.is_active = true;
    
  EXCEPTION WHEN OTHERS THEN
    error_msg := SQLERRM;
    processed_count := 0;
    total_amount := 0;
    completed_count := 0;
  END;
  
  RETURN QUERY SELECT 
    CASE 
      WHEN error_msg IS NOT NULL THEN format('エラーが発生しました: %s', error_msg)
      WHEN processed_count > 0 THEN format('%s の日利計算が完了しました (%s)', calc_date, debug_info)
      ELSE format('処理対象のNFTがありませんでした (%s)', debug_info)
    END::TEXT,
    processed_count::INTEGER,
    total_amount::DECIMAL,
    completed_count::INTEGER,
    error_msg::TEXT;
END;
$$ LANGUAGE plpgsql;

-- 3. 今日の日利計算を強制実行
SELECT * FROM calculate_daily_rewards_batch(CURRENT_DATE);
