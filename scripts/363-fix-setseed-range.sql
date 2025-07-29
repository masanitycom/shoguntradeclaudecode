-- =====================================================================
-- setseed が [-1,1] しか受け取れない問題を修正
-- 旧 uuid 版関数を削除し、seed 値を 0〜1 に正規化した新関数を作成
-- =====================================================================

/* 1. 旧関数を削除 ---------------------------------------------------- */
DROP FUNCTION IF EXISTS public.create_synchronized_weekly_distribution(
  p_week_start_date date,
  p_group_id        uuid,
  p_weekly_rate     numeric
);

/* 2. 正規化版を作成 -------------------------------------------------- */
CREATE OR REPLACE FUNCTION public.create_synchronized_weekly_distribution(
  p_week_start_date date,
  p_group_id        uuid,
  p_weekly_rate     numeric        -- 例: 0.026 (＝2.6%)
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  -- 乱数配分用
  v_rates numeric[5];
  v_zero_cnt int;
  v_total numeric;
  v_scale numeric;

  -- 日別レート
  v_mon numeric;
  v_tue numeric;
  v_wed numeric;
  v_thu numeric;
  v_fri numeric;

  v_week_end date := p_week_start_date + 4;         -- 金曜日
  v_week_no  int  := extract(week from p_week_start_date);
BEGIN
  /* ------------------------------------------------------------------
     1) 週＋グループ重複を避けるため既存行を削除
  ------------------------------------------------------------------ */
  DELETE FROM group_weekly_rates
   WHERE week_start_date = p_week_start_date
     AND group_id        = p_group_id;

  /* ------------------------------------------------------------------
     2) 乱数シードを日付から決定（範囲 0-1 に正規化）
        例: 2025-07-02 → epoch=1751491200
              1751491200 % 100000 = 91200
              91200 / 100000.0    = 0.912
  ------------------------------------------------------------------ */
  PERFORM setseed(
    ((extract(epoch from p_week_start_date)::int % 100000) / 100000.0)::double precision
  );

  /* ------------------------------------------------------------------
     3) ランダム配分（0% の曜日を 0-2 日作る）
  ------------------------------------------------------------------ */
  FOR i IN 1..4 LOOP
    v_rates[i] := random();          -- 月〜木
  END LOOP;
  v_rates[5] := 0;                   -- 金は後で残りを入れる

  -- 0% にする曜日を決定
  v_zero_cnt := floor(random()*3);   -- 0,1,2
  FOR i IN 1..v_zero_cnt LOOP
    PERFORM
      CASE
        -- 重複選択を避けるため while で回す
        WHEN TRUE THEN
          LOOP
            DECLARE v_idx int := floor(random()*5)+1;  -- 1-5
            EXIT WHEN v_rates[v_idx] <> 0;
            v_rates[v_idx] := 0;
            EXIT;
          END LOOP;
      END;
  END LOOP;

  /* ------------------------------------------------------------------
     4) 残りはランダムのまま、合計を weekly_rate に合わせてスケール
  ------------------------------------------------------------------ */
  v_total := v_rates[1] + v_rates[2] + v_rates[3] + v_rates[4] + v_rates[5];
  IF v_total = 0 THEN
    -- すべて 0 になるのは想定外なので均等配分
    v_rates := ARRAY[
      0.2, 0.2, 0.2, 0.2, 0.2
    ];
    v_total := 1;
  END IF;

  v_scale := p_weekly_rate / v_total;
  v_mon := round(v_rates[1] * v_scale, 8);
  v_tue := round(v_rates[2] * v_scale, 8);
  v_wed := round(v_rates[3] * v_scale, 8);
  v_thu := round(v_rates[4] * v_scale, 8);
  v_fri := round(v_rates[5] * v_scale, 8);

  /* ------------------------------------------------------------------
     5) INSERT
  ------------------------------------------------------------------ */
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
