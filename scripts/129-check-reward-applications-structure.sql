-- reward_applicationsテーブルの構造を確認
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'reward_applications' 
ORDER BY ordinal_position;

-- 複利処理関数を正しい構造で修正
CREATE OR REPLACE FUNCTION execute_weekly_compound_processing()
RETURNS TABLE(
  processed_users INTEGER,
  total_compound_amount DECIMAL,
  execution_time INTERVAL
) AS $$
DECLARE
  batch_id UUID;
  start_time TIMESTAMP WITH TIME ZONE;
  processed_count INTEGER := 0;
  total_compound DECIMAL := 0;
  user_record RECORD;
  compound_amount DECIMAL;
  fee_rate DECIMAL;
BEGIN
  start_time := NOW();
  
  -- バッチ実行履歴に記録
  INSERT INTO batch_execution_history (batch_type, status)
  VALUES ('weekly_compound_processing', 'running')
  RETURNING id INTO batch_id;
  
  -- 未申請報酬がある全ユーザーを処理（daily_rewardsテーブルから計算）
  FOR user_record IN
    SELECT 
      u.id,
      u.name,
      COALESCE(SUM(dr.reward_amount), 0) as unclaimed_rewards
    FROM users u
    LEFT JOIN daily_rewards dr ON u.id = dr.user_id 
      AND dr.is_claimed = false
      AND dr.reward_date < CURRENT_DATE - INTERVAL '7 days'
    WHERE u.is_admin = false
    GROUP BY u.id, u.name
    HAVING COALESCE(SUM(dr.reward_amount), 0) > 0
  LOOP
    compound_amount := user_record.unclaimed_rewards;
    
    -- 手数料率を決定（EVOカード保有者は5.5%、その他は8%）
    SELECT CASE 
      WHEN EXISTS(
        SELECT 1 FROM user_nfts un 
        JOIN nfts n ON un.nft_id = n.id 
        WHERE un.user_id = user_record.id 
        AND n.name ILIKE '%EVO%' 
        AND un.is_active = true
      ) THEN 0.055
      ELSE 0.08
    END INTO fee_rate;
    
    -- 手数料を差し引いた複利額を計算
    compound_amount := compound_amount * (1 - fee_rate);
    
    -- 複利処理を実行
    PERFORM process_compound_interest(user_record.id, compound_amount);
    
    total_compound := total_compound + compound_amount;
    processed_count := processed_count + 1;
  END LOOP;
  
  -- バッチ実行履歴を更新
  UPDATE batch_execution_history
  SET 
    status = 'completed',
    end_time = NOW(),
    affected_records = processed_count,
    execution_details = jsonb_build_object(
      'processed_users', processed_count,
      'total_compound_amount', total_compound
    )
  WHERE id = batch_id;
  
  RETURN QUERY SELECT 
    processed_count,
    total_compound,
    NOW() - start_time;
END;
$$ LANGUAGE plpgsql;

-- テスト実行
SELECT 'Testing compound processing with daily_rewards...' as status;

-- 複利処理テスト  
SELECT * FROM execute_weekly_compound_processing();

-- 統合バッチテスト
SELECT * FROM execute_weekly_batch();

SELECT 'Weekly batch system completed successfully' as status;
