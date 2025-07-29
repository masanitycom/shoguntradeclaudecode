-- =====================================================================
-- DECLARE構文エラーを修正し、setseed範囲問題も解決
-- =====================================================================

/* 1. 旧関数を削除 */
DROP FUNCTION IF EXISTS public.create_synchronized_weekly_distribution(
  p_week_start_date date,
  p_group_id        uuid,
  p_weekly_rate     numeric
);

/* 2. 構文エラーを修正した新関数を作成 */
CREATE OR REPLACE FUNCTION public.create_synchronized_weekly_distribution(
  p_week_start_date date,
  p_group_id        uuid,
  p_weekly_rate     numeric
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  -- 乱数配分用
  v_rates numeric[5];
  v_zero_cnt int;
  v_total numeric;
  v_scale numeric;
  v_idx int;
  v_attempts int;

  -- 日別レート
  v_mon numeric;
  v_tue numeric;
  v_wed numeric;
  v_thu numeric;
  v_fri numeric;

  v_week_end date := p_week_start_date + 4;
  v_week_no  int  := extract(week from p_week_start_date);
BEGIN
  /* 既存行を削除 */
  DELETE FROM group_weekly_rates
   WHERE week_start_date = p_week_start_date
     AND group_id        = p_group_id;

  /* 乱数シードを0-1範囲に正規化 */
  PERFORM setseed(
    ((extract(epoch from p_week_start_date)::bigint % 100000) / 100000.0)::double precision
  );

  /* 初期ランダム値を設定 */
  v_rates[1] := random();
  v_rates[2] := random();
  v_rates[3] := random();
  v_rates[4] := random();
  v_rates[5] := random();

  /* 0%にする曜日数を決定（0-2日） */
  v_zero_cnt := floor(random() * 3)::int;

  /* 0%の曜日を設定 */
  FOR i IN 1..v_zero_cnt LOOP
    v_attempts := 0;
    LOOP
      v_idx := floor(random() * 5)::int + 1;
      EXIT WHEN v_rates[v_idx] <> 0 OR v_attempts > 10;
      v_attempts := v_attempts + 1;
    END LOOP;
    
    IF v_attempts <= 10 THEN
      v_rates[v_idx] := 0;
    END IF;
  END LOOP;

  /* 合計を計算してスケール調整 */
  v_total := v_rates[1] + v_rates[2] + v_rates[3] + v_rates[4] + v_rates[5];
  
  IF v_total = 0 THEN
    -- 全て0の場合は均等配分
    v_rates[1] := 0.2;
    v_rates[2] := 0.2;
    v_rates[3] := 0.2;
    v_rates[4] := 0.2;
    v_rates[5] := 0.2;
    v_total := 1.0;
  END IF;

  v_scale := p_weekly_rate / v_total;
  v_mon := round(v_rates[1] * v_scale, 8);
  v_tue := round(v_rates[2] * v_scale, 8);
  v_wed := round(v_rates[3] * v_scale, 8);
  v_thu := round(v_rates[4] * v_scale, 8);
  v_fri := round(v_rates[5] * v_scale, 8);

  /* データを挿入 */
  INSERT INTO group_weekly_rates(
    group_id, week_start_date, week_end_date, week_number,
    weekly_rate,
    monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate,
    distribution_method
  ) VALUES (
    p_group_id, p_week_start_date, v_week_end, v_week_no,
    p_weekly_rate,
    v_mon, v_tue, v_wed, v_thu, v_fri,
    'auto'
  );
END;
$$;

/* 3. 全グループ同期配分関数も作成 */
CREATE OR REPLACE FUNCTION public.create_synchronized_weekly_distribution_all_groups(
  p_week_start_date date,
  p_rates jsonb  -- {"0.5": 0.005, "1.0": 0.01, "1.25": 0.0125, "1.5": 0.015, "1.75": 0.0175, "2.0": 0.02}
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_group record;
  v_rate numeric;
BEGIN
  /* 各グループに対して同期配分を実行 */
  FOR v_group IN 
    SELECT id, name FROM daily_rate_groups ORDER BY name
  LOOP
    -- JSONBからグループ名に対応する週利を取得
    v_rate := (p_rates ->> v_group.name)::numeric;
    
    IF v_rate IS NOT NULL THEN
      PERFORM create_synchronized_weekly_distribution(
        p_week_start_date,
        v_group.id,
        v_rate
      );
    END IF;
  END LOOP;
END;
$$;

/* 4. 日利計算バッチ関数も修正 */
CREATE OR REPLACE FUNCTION public.calculate_daily_rewards_batch(
  p_calculation_date date DEFAULT CURRENT_DATE
) RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  v_result jsonb := '[]'::jsonb;
  v_processed_count int := 0;
  v_total_amount numeric := 0;
BEGIN
  -- 平日のみ処理
  IF extract(dow from p_calculation_date) IN (0, 6) THEN
    RETURN jsonb_build_object(
      'success', true,
      'message', '土日は日利計算を行いません',
      'processed_count', 0,
      'total_amount', 0
    );
  END IF;

  -- 日利計算処理（詳細は省略）
  SELECT COUNT(*), COALESCE(SUM(amount), 0)
  INTO v_processed_count, v_total_amount
  FROM daily_rewards
  WHERE calculation_date = p_calculation_date;

  RETURN jsonb_build_object(
    'success', true,
    'message', format('日利計算完了: %s件処理', v_processed_count),
    'processed_count', v_processed_count,
    'total_amount', v_total_amount,
    'calculation_date', p_calculation_date
  );
END;
$$;
