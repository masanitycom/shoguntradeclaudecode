-- 今週の日利計算を強制実行

-- 1. 今週の週利設定を確認・作成
DO $$
DECLARE
  week_start DATE;
  week_end DATE;
  group_record RECORD;
  rate_exists BOOLEAN;
BEGIN
  -- 今週の月曜日を計算
  week_start := DATE_TRUNC('week', CURRENT_DATE);
  week_end := week_start + INTERVAL '6 days';
  
  RAISE NOTICE '今週の期間: % から %', week_start, week_end;
  
  -- 各グループの週利設定をチェック・作成
  FOR group_record IN 
    SELECT id, group_name FROM daily_rate_groups ORDER BY id
  LOOP
    -- 既存の週利設定があるかチェック
    SELECT EXISTS(
      SELECT 1 FROM group_weekly_rates 
      WHERE group_id = group_record.id 
        AND week_start_date = week_start
    ) INTO rate_exists;
    
    IF NOT rate_exists THEN
      -- デフォルト週利2.6%でランダム分配を作成
      INSERT INTO group_weekly_rates (
        id,
        group_id,
        week_start_date,
        week_end_date,
        weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        distribution_method,
        created_at,
        updated_at
      ) VALUES (
        gen_random_uuid(),
        group_record.id,
        week_start,
        week_end,
        0.026,  -- 2.6%
        0.005,  -- 0.5%
        0.006,  -- 0.6%
        0.005,  -- 0.5%
        0.005,  -- 0.5%
        0.005,  -- 0.5%
        'random',
        NOW(),
        NOW()
      );
      
      RAISE NOTICE 'グループ % の週利設定を作成', group_record.group_name;
    ELSE
      RAISE NOTICE 'グループ % の週利設定は既に存在', group_record.group_name;
    END IF;
  END LOOP;
END $$;

-- 2. 今週の平日分の日利計算を実行
DO $$
DECLARE
  calc_date DATE;
  day_of_week INTEGER;
  calculation_count INTEGER := 0;
BEGIN
  -- 今週の月曜日から今日まで（平日のみ）
  FOR calc_date IN 
    SELECT generate_series(
      DATE_TRUNC('week', CURRENT_DATE),
      CURRENT_DATE,
      '1 day'::interval
    )::date
  LOOP
    -- 曜日チェック（1=月曜日, 5=金曜日）
    day_of_week := EXTRACT(DOW FROM calc_date);
    
    IF day_of_week BETWEEN 1 AND 5 THEN
      -- 既に計算済みかチェック
      IF NOT EXISTS(
        SELECT 1 FROM daily_rewards 
        WHERE reward_date = calc_date
      ) THEN
        -- 日利計算実行
        PERFORM calculate_daily_rewards_for_date(calc_date);
        calculation_count := calculation_count + 1;
        
        RAISE NOTICE '日利計算実行: % (曜日: %)', calc_date, day_of_week;
      ELSE
        RAISE NOTICE '既に計算済み: %', calc_date;
      END IF;
    END IF;
  END LOOP;
  
  RAISE NOTICE '合計 % 日分の計算を実行', calculation_count;
END $$;

-- 3. 計算結果の確認
SELECT 
  'Forced Calculation Results' as result_type,
  dr.reward_date,
  COUNT(DISTINCT dr.user_id) as users_count,
  COUNT(dr.id) as rewards_count,
  SUM(dr.reward_amount) as total_amount,
  AVG(dr.reward_amount) as avg_amount
FROM daily_rewards dr
WHERE dr.reward_date >= DATE_TRUNC('week', CURRENT_DATE)
  AND dr.reward_date <= CURRENT_DATE
GROUP BY dr.reward_date
ORDER BY dr.reward_date;
