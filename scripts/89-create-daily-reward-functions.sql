-- 日利計算用のPostgreSQL関数を作成

-- 1. 営業日判定関数
CREATE OR REPLACE FUNCTION is_business_day(check_date DATE)
RETURNS BOOLEAN AS $$
BEGIN
  -- 月曜日(1)から金曜日(5)のみ営業日
  RETURN EXTRACT(DOW FROM check_date) BETWEEN 1 AND 5;
END;
$$ LANGUAGE plpgsql;

-- 2. 週利配分関数（既存の改良版）
CREATE OR REPLACE FUNCTION distribute_weekly_rate(
  weekly_rate DECIMAL,
  week_start DATE
)
RETURNS TABLE(
  business_date DATE,
  daily_rate DECIMAL
) AS $$
DECLARE
  business_days INTEGER;
  daily_rate_value DECIMAL;
  loop_date DATE;
BEGIN
  -- その週の営業日数を計算
  business_days := 0;
  FOR i IN 0..6 LOOP
    loop_date := week_start + i;
    IF is_business_day(loop_date) THEN
      business_days := business_days + 1;
    END IF;
  END LOOP;
  
  -- 1日あたりの日利を計算
  daily_rate_value := weekly_rate / business_days;
  
  -- 営業日のみ返す
  FOR i IN 0..6 LOOP
    loop_date := week_start + i;
    IF is_business_day(loop_date) THEN
      business_date := loop_date;
      daily_rate := daily_rate_value;
      RETURN NEXT;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 3. 日利計算関数
CREATE OR REPLACE FUNCTION calculate_daily_rewards(
  target_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE(
  user_nft_id UUID,
  user_name TEXT,
  nft_name TEXT,
  investment_amount DECIMAL,
  daily_rate DECIMAL,
  reward_amount DECIMAL,
  total_earned_after DECIMAL,
  max_earning DECIMAL,
  progress_percentage DECIMAL
) AS $$
DECLARE
  week_start DATE;
  weekly_rate_record RECORD;
BEGIN
  -- 対象日の週開始日を計算
  week_start := target_date - EXTRACT(DOW FROM target_date)::INTEGER + 1;
  
  -- その週の週利設定を取得
  SELECT * INTO weekly_rate_record
  FROM weekly_profits 
  WHERE week_start_date = week_start
  LIMIT 1;
  
  -- 週利設定がない場合は終了
  IF weekly_rate_record IS NULL THEN
    RETURN;
  END IF;
  
  -- 営業日でない場合は終了
  IF NOT is_business_day(target_date) THEN
    RETURN;
  END IF;
  
  -- アクティブなユーザーNFTに対して日利計算
  RETURN QUERY
  WITH daily_rates AS (
    SELECT * FROM distribute_weekly_rate(
      weekly_rate_record.total_profit / 100.0, 
      week_start
    ) WHERE business_date = target_date
  ),
  nft_calculations AS (
    SELECT 
      un.id as user_nft_id,
      u.name as user_name,
      n.name as nft_name,
      un.current_investment as investment_amount,
      LEAST(dr.daily_rate, n.daily_rate_limit / 100.0) as daily_rate,
      un.current_investment * LEAST(dr.daily_rate, n.daily_rate_limit / 100.0) as reward_amount,
      un.total_earned,
      un.max_earning
    FROM user_nfts un
    JOIN users u ON un.user_id = u.id
    JOIN nfts n ON un.nft_id = n.id
    CROSS JOIN daily_rates dr
    WHERE un.is_active = true
      AND un.total_earned < un.max_earning
  )
  SELECT 
    nc.user_nft_id,
    nc.user_name,
    nc.nft_name,
    nc.investment_amount,
    nc.daily_rate,
    -- 300%キャップを超えないように調整
    LEAST(nc.reward_amount, nc.max_earning - nc.total_earned) as reward_amount,
    nc.total_earned + LEAST(nc.reward_amount, nc.max_earning - nc.total_earned) as total_earned_after,
    nc.max_earning,
    ((nc.total_earned + LEAST(nc.reward_amount, nc.max_earning - nc.total_earned)) / nc.max_earning * 100) as progress_percentage
  FROM nft_calculations nc;
END;
$$ LANGUAGE plpgsql;

-- 4. 日利報酬記録関数
CREATE OR REPLACE FUNCTION record_daily_rewards(
  target_date DATE DEFAULT CURRENT_DATE
)
RETURNS INTEGER AS $$
DECLARE
  reward_record RECORD;
  records_created INTEGER := 0;
  week_start DATE;
BEGIN
  week_start := target_date - EXTRACT(DOW FROM target_date)::INTEGER + 1;
  
  -- 既に記録済みかチェック
  IF EXISTS (SELECT 1 FROM daily_rewards WHERE reward_date = target_date) THEN
    RAISE NOTICE '日付 % の日利報酬は既に記録済みです', target_date;
    RETURN 0;
  END IF;
  
  -- 日利計算結果を取得して記録
  FOR reward_record IN 
    SELECT * FROM calculate_daily_rewards(target_date)
  LOOP
    -- daily_rewardsテーブルに記録
    INSERT INTO daily_rewards (
      user_nft_id,
      reward_date,
      daily_rate,
      reward_amount,
      week_start_date,
      is_claimed
    ) VALUES (
      reward_record.user_nft_id,
      target_date,
      reward_record.daily_rate,
      reward_record.reward_amount,
      week_start,
      false
    );
    
    -- user_nftsテーブルの累計収益を更新
    UPDATE user_nfts 
    SET 
      total_earned = reward_record.total_earned_after,
      is_active = CASE 
        WHEN reward_record.total_earned_after >= reward_record.max_earning THEN false 
        ELSE true 
      END,
      updated_at = CURRENT_TIMESTAMP
    WHERE id = reward_record.user_nft_id;
    
    records_created := records_created + 1;
  END LOOP;
  
  RETURN records_created;
END;
$$ LANGUAGE plpgsql;

-- テスト用：関数の動作確認
SELECT 'Functions created successfully' as status;
