-- 日利計算を強制実行

-- 1. 現在の週利設定を確認
SELECT 
  'Current Week Rates Check' as check_type,
  gwr.week_start_date,
  gwr.week_end_date,
  drg.group_name,
  drg.daily_rate_limit,
  gwr.weekly_rate,
  gwr.monday_rate,
  gwr.tuesday_rate,
  gwr.wednesday_rate,
  gwr.thursday_rate,
  gwr.friday_rate
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE CURRENT_DATE BETWEEN gwr.week_start_date::DATE AND gwr.week_end_date::DATE
ORDER BY drg.daily_rate_limit;

-- 2. NFTとグループの対応を確認
SELECT 
  'NFT Group Mapping' as check_type,
  n.name as nft_name,
  n.daily_rate_limit,
  drg.group_name,
  COUNT(un.id) as user_count
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
LEFT JOIN user_nfts un ON n.id = un.nft_id AND un.is_active = true
WHERE n.is_active = true
GROUP BY n.id, n.name, n.daily_rate_limit, drg.group_name
ORDER BY n.daily_rate_limit;

-- 3. 日利計算関数を強制作成（既存の場合は上書き）
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
    -- 今日の既存レコードを削除
    DELETE FROM daily_rewards WHERE reward_date = calc_date;
    
    -- 日利計算を実行
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
      WHEN processed_count > 0 THEN format('%s の日利計算が完了しました', calc_date)
      ELSE '処理対象のNFTがありませんでした'
    END::TEXT,
    processed_count::INTEGER,
    total_amount::DECIMAL,
    completed_count::INTEGER,
    error_msg::TEXT;
END;
$$ LANGUAGE plpgsql;

-- 4. 今日の日利計算を実行
SELECT 'Executing Daily Calculation for Today' as status;
SELECT * FROM calculate_daily_rewards_batch(CURRENT_DATE);

-- 5. 過去5営業日の日利計算を実行
DO $$
DECLARE
  calc_date DATE;
  day_of_week INTEGER;
  result_record RECORD;
BEGIN
  RAISE NOTICE '過去5営業日の日利計算を開始します';
  
  -- 過去7日間をチェック（営業日5日分を確保）
  FOR i IN 0..6 LOOP
    calc_date := CURRENT_DATE - i;
    day_of_week := EXTRACT(DOW FROM calc_date);
    
    -- 平日のみ処理
    IF day_of_week BETWEEN 1 AND 5 THEN
      RAISE NOTICE '日利計算実行: % (曜日: %)', calc_date, day_of_week;
      
      -- 日利計算を実行
      FOR result_record IN 
        SELECT * FROM calculate_daily_rewards_batch(calc_date)
      LOOP
        RAISE NOTICE '結果: % - %', calc_date, result_record.message;
        RAISE NOTICE '処理件数: %, 合計金額: %', result_record.processed_count, result_record.total_rewards;
        
        IF result_record.error_message IS NOT NULL THEN
          RAISE NOTICE 'エラー: %', result_record.error_message;
        END IF;
      END LOOP;
    END IF;
  END LOOP;
END $$;

-- 6. 計算結果を確認
SELECT 
  'Daily Rewards Summary' as check_type,
  reward_date,
  COUNT(*) as record_count,
  SUM(reward_amount) as total_amount,
  AVG(reward_amount) as avg_amount,
  MIN(reward_amount) as min_amount,
  MAX(reward_amount) as max_amount
FROM daily_rewards
GROUP BY reward_date
ORDER BY reward_date DESC;

-- 7. ユーザー別の保留中報酬を確認
SELECT 
  'User Pending Rewards' as check_type,
  COALESCE(u.name, u.email) as user_name,
  COUNT(dr.id) as reward_count,
  SUM(dr.reward_amount) as total_pending
FROM users u
JOIN daily_rewards dr ON u.id = dr.user_id
WHERE dr.is_claimed = false
GROUP BY u.id, u.name, u.email
ORDER BY total_pending DESC
LIMIT 15;

-- 8. システム状況の最終確認
SELECT 
  'Final System Status' as status_type,
  'Daily Rewards Records' as metric,
  COUNT(*) as value
FROM daily_rewards

UNION ALL

SELECT 
  'Final System Status' as status_type,
  'Unclaimed Rewards' as metric,
  COUNT(*) as value
FROM daily_rewards
WHERE is_claimed = false

UNION ALL

SELECT 
  'Final System Status' as status_type,
  'Total Pending Amount' as metric,
  COALESCE(SUM(reward_amount), 0) as value
FROM daily_rewards
WHERE is_claimed = false

UNION ALL

SELECT 
  'Final System Status' as status_type,
  'Unique Users with Rewards' as metric,
  COUNT(DISTINCT user_id) as value
FROM daily_rewards
WHERE is_claimed = false;

-- 9. NFT別の報酬統計
SELECT 
  'NFT Reward Statistics' as check_type,
  n.name as nft_name,
  COUNT(dr.id) as reward_count,
  SUM(dr.reward_amount) as total_rewards,
  AVG(dr.reward_amount) as avg_reward,
  COUNT(DISTINCT dr.user_id) as unique_users
FROM daily_rewards dr
JOIN nfts n ON dr.nft_id = n.id
GROUP BY n.id, n.name
ORDER BY total_rewards DESC;

-- 10. 今日の詳細な計算結果
SELECT 
  'Today Detailed Results' as check_type,
  COALESCE(u.name, u.email) as user_name,
  n.name as nft_name,
  dr.purchase_amount,
  dr.daily_rate,
  dr.reward_amount,
  dr.created_at
FROM daily_rewards dr
JOIN users u ON dr.user_id = u.id
JOIN nfts n ON dr.nft_id = n.id
WHERE dr.reward_date = CURRENT_DATE
ORDER BY dr.reward_amount DESC
LIMIT 20;
