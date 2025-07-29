-- グループ別の同期ランダム配分を作成する関数を UUID 対応に置き換え
-- 既存関数があれば削除
DROP FUNCTION IF EXISTS public.create_synchronized_weekly_distribution(
  p_week_start_date date,
  p_group_id        uuid,
  p_weekly_rate     numeric
);

-- UUID 対応版を作成
CREATE OR REPLACE FUNCTION public.create_synchronized_weekly_distribution(
  p_week_start_date date,
  p_group_id        uuid,
  p_weekly_rate     numeric        -- 例: 0.026 (＝2.6%)
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_monday_rate   numeric;
  v_tuesday_rate  numeric;
  v_wednesday_rate numeric;
  v_thursday_rate numeric;
  v_friday_rate   numeric;
  v_pattern jsonb;
  v_week_end date := p_week_start_date + 4;         -- 金曜日
  v_week_no int   := extract(week from p_week_start_date);
BEGIN
  -------------------------------------------------------------------
  -- 既に同じ週 & 同じグループのレコードがあれば削除しておく（UPSERT と衝突しないように）
  -------------------------------------------------------------------
  DELETE FROM group_weekly_rates
   WHERE week_start_date = p_week_start_date
     AND group_id = p_group_id;

  -------------------------------------------------------------------
  -- 1) 週利をランダムだが 0% 曜日が 1-2 日含まれるパターンで配分
  -- ※ 全グループで同じパターンにするために、週開始日ごとに seed を固定
  -------------------------------------------------------------------
  PERFORM setseed(extract(epoch from p_week_start_date)::double precision);

  -- まず月-木分を乱数で作成（残りは金曜日）
  v_pattern := '[]'::jsonb;
  FOR i IN 1..4 LOOP
    v_pattern := v_pattern || to_jsonb(random());
  END LOOP;

  v_pattern := v_pattern || to_jsonb(0);  -- 金曜日用のダミー

  -- 0% にする曜日を 0-2 個ランダムで選択
  FOR i IN 1..floor(random()*3) LOOP
    v_pattern := jsonb_set(v_pattern, ('{'||floor(random()*5)||'}')::text[], to_jsonb(0), false);
  END LOOP;

  -- 合計を取り補正係数を計算
  WITH vals AS (
    SELECT jsonb_array_elements_text(v_pattern)::numeric AS v
  )
  SELECT 
    SUM(CASE WHEN idx=0 THEN v END), 
    SUM(CASE WHEN idx=1 THEN v END), 
    SUM(CASE WHEN idx=2 THEN v END),
    SUM(CASE WHEN idx=3 THEN v END),
    SUM(CASE WHEN idx=4 THEN v END)
  INTO   v_monday_rate, v_tuesday_rate, v_wednesday_rate, v_thursday_rate, v_friday_rate
  FROM (
    SELECT v, row_number() OVER() - 1 AS idx FROM vals
  ) s;

  -- 合計を p_weekly_rate になるようスケール
  DECLARE
    v_total numeric := v_monday_rate + v_tuesday_rate + v_wednesday_rate + v_thursday_rate + v_friday_rate;
    v_scale numeric := CASE WHEN v_total = 0 THEN 0 ELSE p_weekly_rate / v_total END;
  BEGIN
    v_monday_rate    := round(v_monday_rate    * v_scale, 8);
    v_tuesday_rate   := round(v_tuesday_rate   * v_scale, 8);
    v_wednesday_rate := round(v_wednesday_rate * v_scale, 8);
    v_thursday_rate  := round(v_thursday_rate  * v_scale, 8);
    v_friday_rate    := round(v_friday_rate    * v_scale, 8);
  END;

  -------------------------------------------------------------------
  -- 挿入
  -------------------------------------------------------------------
  INSERT INTO group_weekly_rates(
     group_id, week_start_date, week_end_date, week_number,
     weekly_rate,
     monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate,
     distribution_method
  ) VALUES (
     p_group_id, p_week_start_date, v_week_end, v_week_no,
     p_weekly_rate,
     v_monday_rate, v_tuesday_rate, v_wednesday_rate, v_thursday_rate, v_friday_rate,
     'auto'
  );

END;
$$;
