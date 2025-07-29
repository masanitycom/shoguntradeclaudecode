-- 天下統一ボーナス計算・分配関数の作成

-- 1. 天下統一ボーナス計算・分配関数
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
  -- ボーナスプール計算（会社利益の20%）
  bonus_pool := company_profit_param * 0.20;
  
  -- 分配記録を作成
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
  
  -- ランク保有者の分配率合計を計算
  SELECT COALESCE(SUM(mr.bonus_percentage), 0) INTO total_percentage
  FROM user_rank_history urh
  JOIN mlm_ranks mr ON urh.rank_level = mr.rank_level
  WHERE urh.is_current = true AND urh.rank_level > 0;
  
  -- 分配対象者がいない場合は0で終了
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
  
  -- 各ランク保有者にボーナスを分配
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
    -- 個別ボーナス額を計算（分配率に応じて按分）
    bonus_amount := bonus_pool * (user_record.bonus_percentage / total_percentage);
    
    -- ユーザーボーナス記録を作成
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
  
  -- 分配記録を更新
  UPDATE tenka_bonus_distributions 
  SET total_distributed = total_distributed
  WHERE id = distribution_record_id;
  
  -- weekly_profitsテーブルも更新
  INSERT INTO weekly_profits (
    week_start_date,
    week_end_date,
    total_profit,
    mlm_distribution_amount,
    tenka_bonus_pool,
    tenka_bonus_distributed,
    tenka_distribution_id
  ) VALUES (
    week_start_param,
    week_end_param,
    company_profit_param,
    total_distributed,
    bonus_pool,
    true,
    distribution_record_id
  ) ON CONFLICT (week_start_date) DO UPDATE SET
    total_profit = EXCLUDED.total_profit,
    week_end_date = EXCLUDED.week_end_date,
    mlm_distribution_amount = EXCLUDED.mlm_distribution_amount,
    tenka_bonus_pool = EXCLUDED.tenka_bonus_pool,
    tenka_bonus_distributed = EXCLUDED.tenka_bonus_distributed,
    tenka_distribution_id = EXCLUDED.tenka_distribution_id,
    updated_at = CURRENT_TIMESTAMP;
  
  -- 結果を返す
  RETURN QUERY SELECT 
    distribution_record_id,
    bonus_pool,
    total_distributed,
    beneficiary_count;
END;
$$ LANGUAGE plpgsql;

-- 2. ユーザーの天下統一ボーナス履歴取得関数
CREATE OR REPLACE FUNCTION get_user_tenka_bonus_history(user_id_param UUID)
RETURNS TABLE(
  distribution_date DATE,
  rank_name VARCHAR,
  bonus_amount DECIMAL,
  company_profit DECIMAL,
  bonus_pool DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    tbd.week_start_date as distribution_date,
    utb.rank_name,
    utb.bonus_amount,
    tbd.total_company_profit as company_profit,
    tbd.bonus_pool
  FROM user_tenka_bonuses utb
  JOIN tenka_bonus_distributions tbd ON utb.distribution_id = tbd.id
  WHERE utb.user_id = user_id_param
  ORDER BY tbd.week_start_date DESC;
END;
$$ LANGUAGE plpgsql;

-- 3. 天下統一ボーナス統計取得関数
CREATE OR REPLACE FUNCTION get_tenka_bonus_stats()
RETURNS TABLE(
  total_distributions INTEGER,
  total_bonus_pool DECIMAL,
  total_distributed DECIMAL,
  average_weekly_profit DECIMAL,
  current_rank_holders INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::INTEGER as total_distributions,
    COALESCE(SUM(bonus_pool), 0) as total_bonus_pool,
    COALESCE(SUM(total_distributed), 0) as total_distributed,
    COALESCE(AVG(total_company_profit), 0) as average_weekly_profit,
    (SELECT COUNT(*)::INTEGER FROM user_rank_history WHERE is_current = true AND rank_level > 0) as current_rank_holders
  FROM tenka_bonus_distributions;
END;
$$ LANGUAGE plpgsql;

-- 4. テストデータ用のMLMランク保有者を作成
DO $$
DECLARE
  test_user_id UUID;
BEGIN
  -- テストユーザーがいる場合、ランクを付与
  SELECT id INTO test_user_id FROM users WHERE user_id = 'ohtakiyo' LIMIT 1;
  
  IF test_user_id IS NOT NULL THEN
    -- 既存のランク履歴を無効化
    UPDATE user_rank_history 
    SET is_current = false 
    WHERE user_id = test_user_id;
    
    -- 足軽ランクを付与
    INSERT INTO user_rank_history (
      user_id,
      rank_level,
      rank_name,
      achieved_date,
      is_current,
      nft_value_at_time,
      organization_volume_at_time
    ) VALUES (
      test_user_id,
      1,
      '足軽',
      CURRENT_DATE,
      true,
      1000,
      1500
    );
    
    RAISE NOTICE 'Test user % assigned 足軽 rank', test_user_id;
  ELSE
    RAISE NOTICE 'Test user ohtakiyo not found';
  END IF;
END $$;

-- 5. 確認
SELECT 'Tenka bonus functions created successfully' as status;

-- 6. 現在のランク保有者を確認
SELECT 
  u.name,
  u.user_id,
  urh.rank_name,
  mr.bonus_percentage
FROM user_rank_history urh
JOIN users u ON urh.user_id = u.id
JOIN mlm_ranks mr ON urh.rank_level = mr.rank_level
WHERE urh.is_current = true AND urh.rank_level > 0
ORDER BY urh.rank_level DESC;
