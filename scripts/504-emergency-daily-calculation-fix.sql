-- 緊急：日利計算システムの完全修正

-- 1. 既存の関数を削除
DROP FUNCTION IF EXISTS calculate_daily_rewards_batch(DATE);
DROP FUNCTION IF EXISTS calculate_daily_rewards_batch();
DROP FUNCTION IF EXISTS calculate_daily_rewards_by_date(DATE, DATE);

-- 2. 日利計算関数を新規作成（確実に動作するバージョン）
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
    -- 日利計算を実行
    WITH daily_calculation AS (
      SELECT 
        un.user_id,
        un.nft_id,
        un.current_investment,
        n.daily_rate_limit,
        CASE 
          WHEN day_of_week = 1 THEN COALESCE(gwr.monday_rate, 0)
          WHEN day_of_week = 2 THEN COALESCE(gwr.tuesday_rate, 0)
          WHEN day_of_week = 3 THEN COALESCE(gwr.wednesday_rate, 0)
          WHEN day_of_week = 4 THEN COALESCE(gwr.thursday_rate, 0)
          WHEN day_of_week = 5 THEN COALESCE(gwr.friday_rate, 0)
          ELSE 0
        END as daily_rate
      FROM user_nfts un
      JOIN nfts n ON un.nft_id = n.id
      JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
      LEFT JOIN group_weekly_rates gwr ON drg.id = gwr.group_id 
        AND calc_date BETWEEN gwr.week_start_date::DATE AND gwr.week_end_date::DATE
      WHERE un.is_active = true
        AND un.current_investment > 0
        AND n.is_active = true
    ),
    reward_calculation AS (
      SELECT 
        user_id,
        nft_id,
        current_investment,
        LEAST(daily_rate, daily_rate_limit) as effective_rate,
        current_investment * LEAST(daily_rate, daily_rate_limit) as reward_amount
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
    FROM reward_calculation
    ON CONFLICT (user_id, nft_id, reward_date) DO UPDATE SET
      purchase_amount = EXCLUDED.purchase_amount,
      daily_rate = EXCLUDED.daily_rate,
      reward_amount = EXCLUDED.reward_amount,
      updated_at = NOW();
    
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
      WHEN processed_count > 0 THEN format('%s の日利計算が完了しました', calc_date)
      ELSE '処理対象のNFTがありませんでした'
    END::TEXT,
    processed_count::INTEGER,
    total_amount::DECIMAL,
    completed_count::INTEGER,
    error_msg::TEXT;
END;
$$ LANGUAGE plpgsql;

-- 3. テスト実行
SELECT '日利計算関数を作成しました' as status;

-- 4. 今日の日利計算を強制実行
SELECT * FROM calculate_daily_rewards_batch(CURRENT_DATE);

-- 5. 結果確認
SELECT 
  'システム確認' as check_type,
  COUNT(*) as count,
  COALESCE(SUM(reward_amount), 0) as total_rewards
FROM daily_rewards 
WHERE reward_date = CURRENT_DATE;

-- 6. ユーザー別の今日の報酬確認
SELECT 
  u.name,
  u.email,
  COUNT(dr.id) as reward_count,
  COALESCE(SUM(dr.reward_amount), 0) as total_daily_reward
FROM users u
LEFT JOIN daily_rewards dr ON u.id = dr.user_id AND dr.reward_date = CURRENT_DATE
WHERE u.is_admin = false
GROUP BY u.id, u.name, u.email
ORDER BY total_daily_reward DESC;
