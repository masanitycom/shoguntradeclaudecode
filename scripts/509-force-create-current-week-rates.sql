-- 今週の週利設定を強制作成

-- 1. 今週の月曜日を計算
WITH current_week AS (
  SELECT 
    (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day')::DATE as week_start,
    (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '7 days')::DATE as week_end
)
SELECT 
  'Current Week Calculation' as info,
  week_start,
  week_end,
  CURRENT_DATE as today,
  EXTRACT(DOW FROM CURRENT_DATE) as day_of_week
FROM current_week;

-- 2. 今週の週利設定が存在するかチェック
WITH current_week AS (
  SELECT 
    (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day')::DATE as week_start,
    (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '7 days')::DATE as week_end
)
SELECT 
  'Current Week Rates Check' as check_type,
  COUNT(*) as existing_rates
FROM group_weekly_rates gwr
CROSS JOIN current_week cw
WHERE gwr.week_start_date = cw.week_start;

-- 3. 今週の週利設定を強制作成（存在しない場合）
DO $$
DECLARE
  week_start_date DATE;
  week_end_date DATE;
  week_num INTEGER;
  group_record RECORD;
  rates RECORD;
BEGIN
  -- 今週の月曜日と日曜日を計算
  week_start_date := (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day')::DATE;
  week_end_date := (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '7 days')::DATE;
  week_num := EXTRACT(WEEK FROM week_start_date);
  
  -- 既存の設定を削除
  DELETE FROM group_weekly_rates WHERE week_start_date = week_start_date;
  
  -- 各グループに対して週利設定を作成
  FOR group_record IN 
    SELECT id, group_name, daily_rate_limit FROM daily_rate_groups ORDER BY daily_rate_limit
  LOOP
    -- ランダム配分を生成（週利2.6%をベースに）
    WITH random_distribution AS (
      SELECT 
        0.005 + (RANDOM() * 0.005) as monday_rate,
        0.005 + (RANDOM() * 0.005) as tuesday_rate,
        0.005 + (RANDOM() * 0.005) as wednesday_rate,
        0.005 + (RANDOM() * 0.005) as thursday_rate,
        0.005 + (RANDOM() * 0.005) as friday_rate
    )
    SELECT * INTO rates FROM random_distribution;
    
    -- 週利設定を挿入
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
    ) VALUES (
      group_record.id,
      week_start_date,
      week_end_date,
      week_num,
      0.026, -- 2.6%
      rates.monday_rate,
      rates.tuesday_rate,
      rates.wednesday_rate,
      rates.thursday_rate,
      rates.friday_rate,
      'EMERGENCY_AUTO_GENERATED',
      NOW()
    );
    
    RAISE NOTICE '週利設定を作成: % (%.1%% 日利上限)', group_record.group_name, group_record.daily_rate_limit * 100;
  END LOOP;
  
  RAISE NOTICE '今週の週利設定を完了しました: % - %', week_start_date, week_end_date;
END $$;

-- 4. 作成された週利設定を確認
SELECT 
  'Created Weekly Rates' as check_type,
  gwr.week_start_date,
  gwr.week_end_date,
  drg.group_name,
  gwr.weekly_rate,
  gwr.monday_rate,
  gwr.tuesday_rate,
  gwr.wednesday_rate,
  gwr.thursday_rate,
  gwr.friday_rate
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day')::DATE
ORDER BY drg.daily_rate_limit;

-- 5. 日利計算を再実行
SELECT * FROM calculate_daily_rewards_batch(CURRENT_DATE);
