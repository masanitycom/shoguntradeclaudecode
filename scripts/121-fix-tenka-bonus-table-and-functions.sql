-- tenka_bonus_distributionsテーブル構造を確認して修正

-- 1. 現在のテーブル構造を確認
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'tenka_bonus_distributions' 
ORDER BY ordinal_position;

-- 2. week_end_dateカラムを追加
ALTER TABLE tenka_bonus_distributions 
ADD COLUMN IF NOT EXISTS week_end_date DATE;

-- 3. 天下統一ボーナス関数を修正
CREATE OR REPLACE FUNCTION calculate_and_distribute_tenka_bonus(
  company_profit_param DECIMAL,
  week_start_param DATE,
  week_end_param DATE
)
RETURNS TABLE(
  distribution_id UUID,
  total_bonus_pool DECIMAL,
  distributed_amount DECIMAL,
  beneficiary_count INTEGER
) AS $$
DECLARE
  bonus_pool DECIMAL;
  distribution_record_id UUID;
  user_record RECORD;
  bonus_amount DECIMAL;
  total_distributed DECIMAL := 0;
  beneficiary_count INTEGER := 0;
  total_percentage DECIMAL := 0;
BEGIN
  bonus_pool := company_profit_param * 0.20;
  
  INSERT INTO tenka_bonus_distributions (
    week_start_date,
    week_end_date,
    total_company_profit,
    bonus_pool
  ) VALUES (
    week_start_param,
    week_end_param,
    company_profit_param,
    bonus_pool
  ) RETURNING id INTO distribution_record_id;
  
  SELECT COALESCE(SUM(mr.bonus_percentage), 0) INTO total_percentage
  FROM user_rank_history urh
  JOIN mlm_ranks mr ON urh.rank_level = mr.rank_level
  WHERE urh.is_current = true AND urh.rank_level > 0;
  
  IF total_percentage = 0 THEN
    UPDATE tenka_bonus_distributions 
    SET total_distributed = 0
    WHERE id = distribution_record_id;
    
    RETURN QUERY SELECT 
      distribution_record_id,
      bonus_pool,
      0::DECIMAL,
      0;
    RETURN;
  END IF;
  
  FOR user_record IN
    SELECT 
      urh.user_id,
      urh.rank_level,
      mr.rank_name,
      mr.bonus_percentage,
      u.name as user_name
    FROM user_rank_history urh
    JOIN mlm_ranks mr ON urh.rank_level = mr.rank_level
    JOIN users u ON urh.user_id = u.id
    WHERE urh.is_current = true AND urh.rank_level > 0
  LOOP
    bonus_amount := bonus_pool * (user_record.bonus_percentage / total_percentage);
    
    INSERT INTO user_tenka_bonuses (
      distribution_id,
      user_id,
      rank_level,
      rank_name,
      bonus_percentage,
      bonus_amount
    ) VALUES (
      distribution_record_id,
      user_record.user_id,
      user_record.rank_level,
      user_record.rank_name,
      user_record.bonus_percentage,
      bonus_amount
    );
    
    total_distributed := total_distributed + bonus_amount;
    beneficiary_count := beneficiary_count + 1;
  END LOOP;
  
  UPDATE tenka_bonus_distributions 
  SET total_distributed = total_distributed
  WHERE id = distribution_record_id;
  
  RETURN QUERY SELECT 
    distribution_record_id,
    bonus_pool,
    total_distributed,
    beneficiary_count;
END;
$$ LANGUAGE plpgsql;

-- 4. テスト実行
SELECT * FROM calculate_and_distribute_tenka_bonus(
  100000.00,
  '2024-01-01'::DATE,
  '2024-01-07'::DATE
);

SELECT 'System fixed and tested successfully' as status;
