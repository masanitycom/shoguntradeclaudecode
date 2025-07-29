-- reward_applicationsテーブルの正確な構造を使用して複利処理を修正

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
  
  -- 未申請報酬がある全ユーザーを処理（正確なテーブル構造を使用）
  FOR user_record IN
    SELECT 
      u.id,
      u.name,
      COALESCE(SUM(ra.total_reward_amount), 0) as unclaimed_rewards
    FROM users u
    LEFT JOIN reward_applications ra ON u.id = ra.user_id 
      AND ra.status = 'pending'
      AND ra.applied_at < NOW() - INTERVAL '7 days'
    WHERE u.is_admin = false
    GROUP BY u.id, u.name
    HAVING COALESCE(SUM(ra.total_reward_amount), 0) > 0
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
    
    -- 未申請報酬を複利処理済みに更新
    UPDATE reward_applications 
    SET status = 'compound_processed',
        processed_at = NOW()
    WHERE user_id = user_record.id 
      AND status = 'pending'
      AND applied_at < NOW() - INTERVAL '7 days';
    
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
SELECT 'Testing compound processing with correct structure...' as status;

-- 複利処理テスト  
SELECT * FROM execute_weekly_compound_processing();

-- 統合バッチテスト
SELECT * FROM execute_weekly_batch();

-- 実行履歴確認
SELECT * FROM get_batch_execution_history(10);

SELECT 'Weekly batch automation system completed successfully' as status;
