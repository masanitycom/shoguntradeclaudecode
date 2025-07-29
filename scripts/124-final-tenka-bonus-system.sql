-- 既存関数を削除してから再作成（修正版）

-- 1. 既存関数を削除
DROP FUNCTION IF EXISTS calculate_and_distribute_tenka_bonus(DECIMAL, DATE, DATE);
DROP FUNCTION IF EXISTS calculate_and_distribute_tenka_bonus(DECIMAL, DATE);
DROP FUNCTION IF EXISTS get_user_tenka_bonus_history(UUID);
DROP FUNCTION IF EXISTS get_tenka_bonus_stats();

-- 2. 実際の構造に合わせた天下統一ボーナス分配関数
CREATE OR REPLACE FUNCTION calculate_and_distribute_tenka_bonus(
  company_profit_param DECIMAL,
  week_start_param DATE
)
RETURNS TABLE(
  total_bonus_pool DECIMAL,
  distributed_amount DECIMAL,
  beneficiary_count INTEGER
) AS $$
DECLARE
  bonus_pool DECIMAL;
  user_record RECORD;
  bonus_amount DECIMAL;
  total_distributed DECIMAL := 0;
  beneficiary_count INTEGER := 0;
  total_percentage DECIMAL := 0;
BEGIN
  -- ボーナスプール計算（会社利益の20%）
  bonus_pool := company_profit_param * 0.20;
  
  -- ランク保有者の分配率合計を計算
  SELECT COALESCE(SUM(mr.bonus_percentage), 0) INTO total_percentage
  FROM user_rank_history urh
  JOIN mlm_ranks mr ON urh.rank_level = mr.rank_level
  WHERE urh.is_current = true AND urh.rank_level > 0;
  
  -- 分配対象者がいない場合は0で終了
  IF total_percentage = 0 THEN
    RETURN QUERY SELECT 
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
    
    -- 実際のテーブル構造に合わせてレコードを作成
    INSERT INTO tenka_bonus_distributions (
      week_start_date,
      total_company_profit,
      distribution_amount,
      user_id,
      user_rank,
      distribution_rate,
      bonus_amount
    ) VALUES (
      week_start_param,
      company_profit_param,
      bonus_pool,
      user_record.user_id,
      user_record.rank_name,
      user_record.bonus_percentage,
      bonus_amount
    );
    
    total_distributed := total_distributed + bonus_amount;
    beneficiary_count := beneficiary_count + 1;
  END LOOP;
  
  -- 結果を返す
  RETURN QUERY SELECT 
    bonus_pool,
    total_distributed,
    beneficiary_count;
END;
$$ LANGUAGE plpgsql;

-- 3. ユーザーの天下統一ボーナス履歴取得関数
CREATE OR REPLACE FUNCTION get_user_tenka_bonus_history(user_id_param UUID)
RETURNS TABLE(
  distribution_date DATE,
  rank_name VARCHAR,
  bonus_amount DECIMAL,
  company_profit DECIMAL,
  distribution_pool DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    tbd.week_start_date as distribution_date,
    tbd.user_rank as rank_name,
    tbd.bonus_amount,
    tbd.total_company_profit as company_profit,
    tbd.distribution_amount as distribution_pool
  FROM tenka_bonus_distributions tbd
  WHERE tbd.user_id = user_id_param
  ORDER BY tbd.week_start_date DESC;
END;
$$ LANGUAGE plpgsql;

-- 4. 天下統一ボーナス統計取得関数
CREATE OR REPLACE FUNCTION get_tenka_bonus_stats()
RETURNS TABLE(
  total_distributions INTEGER,
  total_bonus_distributed DECIMAL,
  average_weekly_profit DECIMAL,
  current_rank_holders INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(DISTINCT week_start_date)::INTEGER as total_distributions,
    COALESCE(SUM(bonus_amount), 0) as total_bonus_distributed,
    COALESCE(AVG(total_company_profit), 0) as average_weekly_profit,
    (SELECT COUNT(*)::INTEGER FROM user_rank_history WHERE is_current = true AND rank_level > 0) as current_rank_holders
  FROM tenka_bonus_distributions;
END;
$$ LANGUAGE plpgsql;

-- 5. ohtakiyoユーザーに足軽ランクを付与（修正版）
DO $$
DECLARE
  test_user_id UUID;
BEGIN
  -- ohtakiyoユーザーを検索
  SELECT id INTO test_user_id FROM users WHERE name = 'ohtakiyo' LIMIT 1;
  
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
      organization_volume,
      max_line_volume,
      other_lines_volume,
      qualified_date,
      is_current,
      nft_value_at_time,
      organization_volume_at_time
    ) VALUES (
      test_user_id,
      1, -- 足軽
      '足軽',
      1500,
      800,
      700,
      CURRENT_DATE,
      true,
      1000,
      1500
    );
    
    RAISE NOTICE 'Assigned 足軽 rank to user: %', test_user_id;
  ELSE
    RAISE NOTICE 'User ohtakiyo not found';
  END IF;
END $$;

-- 6. テスト実行
SELECT * FROM calculate_and_distribute_tenka_bonus(
  100000.00,
  '2024-01-01'::DATE
);

-- 7. 結果確認
SELECT 
  'Distribution Results:' as info,
  week_start_date,
  user_rank,
  bonus_amount,
  total_company_profit
FROM tenka_bonus_distributions 
ORDER BY week_start_date DESC, bonus_amount DESC;

-- 8. 現在のランク保有者確認
SELECT 
  'Current Rank Holders:' as info,
  u.name,
  urh.rank_name,
  urh.organization_volume
FROM user_rank_history urh
JOIN users u ON urh.user_id = u.id
WHERE urh.is_current = true AND urh.rank_level > 0;

SELECT 'Tenka bonus system completed successfully' as status;
