-- daily_rewardsテーブル構造の不整合を修正

-- 1. 現在のテーブル構造を確認
SELECT 
  'Current daily_rewards structure analysis' as info,
  column_name,
  data_type,
  is_nullable,
  CASE WHEN is_nullable = 'NO' THEN 'REQUIRED' ELSE 'OPTIONAL' END as requirement
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
  AND table_schema = 'public'
ORDER BY 
  CASE WHEN is_nullable = 'NO' THEN 1 ELSE 2 END,
  ordinal_position;

-- 2. usersテーブルの構造を確認
SELECT 
  'Users table structure' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. user_nftsテーブルとの関係を確認
SELECT 
  'user_nfts sample data' as info,
  un.id as user_nft_id,
  un.user_id,
  un.nft_id,
  un.current_investment,
  un.is_active,
  COALESCE(u.name, u.email, u.id::text) as user_identifier,
  n.name as nft_name
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true 
  AND un.current_investment > 0
LIMIT 5;

-- 4. 日利計算関数を正しい構造に修正
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
  week_start_date DATE;
BEGIN
  -- 曜日を取得（0=日曜、1=月曜、...、6=土曜）
  day_of_week := EXTRACT(DOW FROM calc_date);
  
  -- 週の開始日を計算（月曜日）
  week_start_date := (DATE_TRUNC('week', calc_date) + INTERVAL '1 day')::DATE;
  
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
    SELECT format('計算日: %s, 曜日: %s, 週開始: %s', calc_date, day_of_week, week_start_date) INTO debug_info;
    
    -- 今日の既存レコードを削除
    DELETE FROM daily_rewards WHERE reward_date = calc_date;
    
    -- 日利計算を実行（user_nft_idベース）
    WITH week_rates_data AS (
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
      WHERE gwr.week_start_date = week_start_date
    ),
    eligible_user_nfts AS (
      SELECT 
        un.id as user_nft_id,
        un.user_id,
        un.nft_id,
        un.current_investment,
        n.name as nft_name,
        n.daily_rate_limit,
        wrd.group_id,
        wrd.group_name,
        CASE 
          WHEN day_of_week = 1 THEN wrd.monday_rate
          WHEN day_of_week = 2 THEN wrd.tuesday_rate
          WHEN day_of_week = 3 THEN wrd.wednesday_rate
          WHEN day_of_week = 4 THEN wrd.thursday_rate
          WHEN day_of_week = 5 THEN wrd.friday_rate
          ELSE 0
        END as daily_rate,
        wrd.week_start_date
      FROM user_nfts un
      JOIN nfts n ON un.nft_id = n.id
      JOIN week_rates_data wrd ON n.daily_rate_limit = wrd.daily_rate_limit
      WHERE un.is_active = true
        AND un.current_investment > 0
        AND n.is_active = true
    ),
    reward_calculations AS (
      SELECT 
        user_nft_id,
        user_id,
        nft_id,
        current_investment,
        nft_name,
        daily_rate_limit,
        daily_rate,
        week_start_date,
        LEAST(daily_rate, daily_rate_limit) as effective_rate,
        current_investment * LEAST(daily_rate, daily_rate_limit) as reward_amount
      FROM eligible_user_nfts
      WHERE daily_rate > 0
    )
    INSERT INTO daily_rewards (
      user_nft_id,
      user_id,
      nft_id,
      reward_date,
      week_start_date,
      investment_amount,
      purchase_amount,
      daily_rate,
      reward_amount,
      is_claimed,
      created_at
    )
    SELECT 
      user_nft_id,
      user_id,
      nft_id,
      calc_date,
      week_start_date,
      current_investment,
      current_investment, -- purchase_amountとinvestment_amountは同じ値
      effective_rate,
      reward_amount,
      false,
      NOW()
    FROM reward_calculations;
    
    -- 処理件数を取得
    GET DIAGNOSTICS processed_count = ROW_COUNT;
    
    -- 合計金額を計算
    SELECT COALESCE(SUM(reward_amount), 0) INTO total_amount
    FROM daily_rewards 
    WHERE reward_date = calc_date;
    
    -- 完了NFT数を計算（300%達成の概算）
    SELECT COUNT(*) INTO completed_count
    FROM user_nfts un
    WHERE EXISTS (
      SELECT 1 FROM daily_rewards dr 
      WHERE dr.user_nft_id = un.id 
      GROUP BY dr.user_nft_id 
      HAVING SUM(dr.reward_amount) >= un.current_investment * 3.0
    );
    
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

-- 5. 週利設定の存在確認と作成
DO $$
DECLARE
  current_week_start DATE;
  rates_count INTEGER;
BEGIN
  current_week_start := (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day')::DATE;
  
  SELECT COUNT(*) INTO rates_count
  FROM group_weekly_rates
  WHERE week_start_date = current_week_start;
  
  IF rates_count = 0 THEN
    RAISE NOTICE '今週の週利設定が見つかりません。作成します...';
    
    -- 各グループに対して週利設定を作成
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
      'AUTO_GENERATED_EMERGENCY',
      NOW()
    FROM daily_rate_groups drg;
    
    RAISE NOTICE '今週の週利設定を作成しました: %', current_week_start;
  ELSE
    RAISE NOTICE '今週の週利設定が存在します: % 件', rates_count;
  END IF;
END $$;

-- 6. システム状況を確認
SELECT 
  'System Status Check' as check_type,
  (SELECT COUNT(*) FROM user_nfts WHERE is_active = true AND current_investment > 0) as active_user_nfts,
  (SELECT COUNT(*) FROM group_weekly_rates WHERE week_start_date = (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day')::DATE) as current_week_rates,
  (SELECT COUNT(*) FROM daily_rate_groups) as total_groups,
  EXTRACT(DOW FROM CURRENT_DATE) as current_day_of_week,
  CASE WHEN EXTRACT(DOW FROM CURRENT_DATE) BETWEEN 1 AND 5 THEN 'WEEKDAY' ELSE 'WEEKEND' END as day_type;
