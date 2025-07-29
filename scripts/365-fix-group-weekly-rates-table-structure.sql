-- =====================================================================
-- group_weekly_ratesテーブル構造を修正し、関数も正しく作成
-- =====================================================================

-- 1. 既存のテーブル構造を確認
SELECT 
    '📊 現在のテーブル構造確認' as status,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates' 
ORDER BY ordinal_position;

-- 2. 不足しているカラムを追加
DO $$
BEGIN
    -- week_end_dateカラムが存在しない場合は追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'group_weekly_rates' AND column_name = 'week_end_date'
    ) THEN
        ALTER TABLE group_weekly_rates ADD COLUMN week_end_date DATE;
    END IF;

    -- week_numberカラムが存在しない場合は追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'group_weekly_rates' AND column_name = 'week_number'
    ) THEN
        ALTER TABLE group_weekly_rates ADD COLUMN week_number INTEGER;
    END IF;

    -- distribution_methodカラムが存在しない場合は追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'group_weekly_rates' AND column_name = 'distribution_method'
    ) THEN
        ALTER TABLE group_weekly_rates ADD COLUMN distribution_method VARCHAR(20) DEFAULT 'auto';
    END IF;

    -- group_idカラムが存在しない場合は追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'group_weekly_rates' AND column_name = 'group_id'
    ) THEN
        ALTER TABLE group_weekly_rates ADD COLUMN group_id UUID;
    END IF;
END $$;

-- 3. 既存データのweek_end_dateとweek_numberを更新
UPDATE group_weekly_rates 
SET 
    week_end_date = week_start_date + INTERVAL '4 days',
    week_number = EXTRACT(week FROM week_start_date)
WHERE week_end_date IS NULL OR week_number IS NULL;

-- 4. 旧関数を削除
DROP FUNCTION IF EXISTS public.create_synchronized_weekly_distribution(date, uuid, numeric);
DROP FUNCTION IF EXISTS public.create_synchronized_weekly_distribution(date, integer, numeric);

-- 5. 正しい関数を作成
CREATE OR REPLACE FUNCTION public.create_synchronized_weekly_distribution(
  p_week_start_date date,
  p_group_id        uuid,
  p_weekly_rate     numeric
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  -- 乱数配分用変数
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
  -- 既存行を削除
  DELETE FROM group_weekly_rates
   WHERE week_start_date = p_week_start_date
     AND group_id        = p_group_id;

  -- 乱数シードを0-1範囲に正規化
  PERFORM setseed(
    ((extract(epoch from p_week_start_date)::bigint % 100000) / 100000.0)::double precision
  );

  -- 初期ランダム値を設定
  v_rates[1] := random();
  v_rates[2] := random();
  v_rates[3] := random();
  v_rates[4] := random();
  v_rates[5] := random();

  -- 0%にする曜日数を決定（0-2日）
  v_zero_cnt := floor(random() * 3)::int;

  -- 0%の曜日を設定
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

  -- 合計を計算してスケール調整
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

  -- データを挿入
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

-- 6. 日利計算バッチ関数を作成
CREATE OR REPLACE FUNCTION public.calculate_daily_rewards_batch(
  p_calculation_date date DEFAULT CURRENT_DATE
) RETURNS jsonb[]
LANGUAGE plpgsql
AS $$
DECLARE
  v_result jsonb[];
  v_processed_count int := 0;
  v_total_amount numeric := 0;
  v_completed_nfts int := 0;
BEGIN
  -- 平日のみ処理
  IF extract(dow from p_calculation_date) IN (0, 6) THEN
    v_result := ARRAY[jsonb_build_object(
      'calculation_date', p_calculation_date,
      'processed_count', 0,
      'total_rewards', 0,
      'completed_nfts', 0,
      'error_message', '土日は日利計算を行いません'
    )];
    RETURN v_result;
  END IF;

  -- 実際の日利計算処理（簡略版）
  SELECT COUNT(*), COALESCE(SUM(amount), 0)
  INTO v_processed_count, v_total_amount
  FROM daily_rewards
  WHERE calculation_date = p_calculation_date;

  -- 完了したNFT数を計算
  SELECT COUNT(DISTINCT user_nft_id)
  INTO v_completed_nfts
  FROM daily_rewards
  WHERE calculation_date = p_calculation_date;

  v_result := ARRAY[jsonb_build_object(
    'calculation_date', p_calculation_date,
    'processed_count', v_processed_count,
    'total_rewards', v_total_amount,
    'completed_nfts', v_completed_nfts,
    'error_message', null
  )];

  RETURN v_result;
END;
$$;

-- 7. 修正後のテーブル構造を確認
SELECT 
    '✅ 修正後のテーブル構造' as status,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates' 
ORDER BY ordinal_position;

-- 8. 制約を確認
SELECT 
    '🔒 テーブル制約確認' as status,
    conname as constraint_name,
    contype as constraint_type
FROM pg_constraint 
WHERE conrelid = 'group_weekly_rates'::regclass;
