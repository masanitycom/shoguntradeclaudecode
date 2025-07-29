-- 週利設定作成の修正（変数名の曖昧性を解決）

-- 1. 今週の週利設定を強制作成（修正版）
DO $$
DECLARE
  v_week_start_date DATE;
  v_week_end_date DATE;
  v_week_num INTEGER;
  group_record RECORD;
  rates RECORD;
BEGIN
  -- 今週の月曜日と日曜日を計算
  v_week_start_date := (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day')::DATE;
  v_week_end_date := (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '7 days')::DATE;
  v_week_num := EXTRACT(WEEK FROM v_week_start_date);
  
  RAISE NOTICE '週利設定を作成中: % - %', v_week_start_date, v_week_end_date;
  
  -- 既存の設定を削除（変数名を明確に指定）
  DELETE FROM group_weekly_rates WHERE group_weekly_rates.week_start_date = v_week_start_date;
  
  -- 各グループに対して週利設定を作成
  FOR group_record IN 
    SELECT id, group_name, daily_rate_limit FROM daily_rate_groups ORDER BY daily_rate_limit
  LOOP
    -- ランダム配分を生成（週利2.6%をベースに）
    WITH random_distribution AS (
      SELECT 
        0.004 + (RANDOM() * 0.006) as monday_rate,    -- 0.4% - 1.0%
        0.004 + (RANDOM() * 0.006) as tuesday_rate,   -- 0.4% - 1.0%
        0.004 + (RANDOM() * 0.006) as wednesday_rate, -- 0.4% - 1.0%
        0.004 + (RANDOM() * 0.006) as thursday_rate,  -- 0.4% - 1.0%
        0.004 + (RANDOM() * 0.006) as friday_rate     -- 0.4% - 1.0%
    )
    SELECT * INTO rates FROM random_distribution;
    
    -- 合計を2.6%に調整
    DECLARE
      total_rate DECIMAL := rates.monday_rate + rates.tuesday_rate + rates.wednesday_rate + rates.thursday_rate + rates.friday_rate;
      adjustment_factor DECIMAL := 0.026 / total_rate;
    BEGIN
      rates.monday_rate := rates.monday_rate * adjustment_factor;
      rates.tuesday_rate := rates.tuesday_rate * adjustment_factor;
      rates.wednesday_rate := rates.wednesday_rate * adjustment_factor;
      rates.thursday_rate := rates.thursday_rate * adjustment_factor;
      rates.friday_rate := rates.friday_rate * adjustment_factor;
    END;
    
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
      v_week_start_date,
      v_week_end_date,
      v_week_num,
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
  
  RAISE NOTICE '今週の週利設定を完了しました: % - %', v_week_start_date, v_week_end_date;
END $$;

-- 2. 作成された週利設定を確認
SELECT 
  'Created Weekly Rates' as check_type,
  gwr.week_start_date,
  gwr.week_end_date,
  drg.group_name,
  ROUND(gwr.weekly_rate * 100, 2) || '%' as weekly_rate,
  ROUND(gwr.monday_rate * 100, 3) || '%' as monday_rate,
  ROUND(gwr.tuesday_rate * 100, 3) || '%' as tuesday_rate,
  ROUND(gwr.wednesday_rate * 100, 3) || '%' as wednesday_rate,
  ROUND(gwr.thursday_rate * 100, 3) || '%' as thursday_rate,
  ROUND(gwr.friday_rate * 100, 3) || '%' as friday_rate
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day')::DATE
ORDER BY drg.daily_rate_limit;

-- 3. 日利計算を再実行
SELECT * FROM calculate_daily_rewards_batch(CURRENT_DATE);
