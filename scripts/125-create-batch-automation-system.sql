-- 週次バッチ処理システムの実装

-- 1. バッチ実行履歴テーブル
CREATE TABLE IF NOT EXISTS batch_execution_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_type VARCHAR(50) NOT NULL,
  execution_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status VARCHAR(20) NOT NULL DEFAULT 'running',
  start_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  end_time TIMESTAMP WITH TIME ZONE,
  affected_records INTEGER DEFAULT 0,
  error_message TEXT,
  execution_details JSONB
);

-- 2. 週次ランク更新バッチ関数
CREATE OR REPLACE FUNCTION execute_weekly_rank_update()
RETURNS TABLE(
  updated_users INTEGER,
  rank_changes INTEGER,
  execution_time INTERVAL
) AS $$
DECLARE
  batch_id UUID;
  start_time TIMESTAMP WITH TIME ZONE;
  updated_count INTEGER := 0;
  rank_change_count INTEGER := 0;
  user_record RECORD;
  current_rank INTEGER;
  new_rank INTEGER;
  user_nft_value DECIMAL;
  org_volume DECIMAL;
  max_line DECIMAL;
  other_lines DECIMAL;
BEGIN
  start_time := NOW();
  
  -- バッチ実行履歴に記録
  INSERT INTO batch_execution_history (batch_type, status)
  VALUES ('weekly_rank_update', 'running')
  RETURNING id INTO batch_id;
  
  -- 全ユーザーのランクを更新
  FOR user_record IN
    SELECT DISTINCT u.id, u.name
    FROM users u
    WHERE u.is_admin = false
  LOOP
    -- 現在のランクを取得
    SELECT COALESCE(rank_level, 0) INTO current_rank
    FROM user_rank_history
    WHERE user_id = user_record.id AND is_current = true;
    
    -- ユーザーのNFT価値を計算
    SELECT COALESCE(SUM(un.investment_amount), 0) INTO user_nft_value
    FROM user_nfts un
    WHERE un.user_id = user_record.id AND un.is_active = true;
    
    -- 組織ボリュームを計算（8段階まで）
    SELECT * INTO org_volume, max_line, other_lines
    FROM calculate_organization_volume(user_record.id);
    
    -- 新しいランクを判定
    SELECT determine_user_rank(user_nft_value, org_volume, max_line, other_lines) INTO new_rank;
    
    -- ランクが変更された場合
    IF current_rank != new_rank THEN
      -- 既存のランク履歴を無効化
      UPDATE user_rank_history 
      SET is_current = false 
      WHERE user_id = user_record.id;
      
      -- 新しいランク履歴を作成
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
      )
      SELECT 
        user_record.id,
        new_rank,
        mr.rank_name,
        org_volume,
        max_line,
        other_lines,
        CURRENT_DATE,
        true,
        user_nft_value,
        org_volume
      FROM mlm_ranks mr
      WHERE mr.rank_level = new_rank;
      
      rank_change_count := rank_change_count + 1;
    END IF;
    
    updated_count := updated_count + 1;
  END LOOP;
  
  -- バッチ実行履歴を更新
  UPDATE batch_execution_history
  SET 
    status = 'completed',
    end_time = NOW(),
    affected_records = updated_count,
    execution_details = jsonb_build_object(
      'updated_users', updated_count,
      'rank_changes', rank_change_count
    )
  WHERE id = batch_id;
  
  RETURN QUERY SELECT 
    updated_count,
    rank_change_count,
    NOW() - start_time;
END;
$$ LANGUAGE plpgsql;

-- 3. 週次複利処理バッチ関数
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
  
  -- 未申請報酬がある全ユーザーを処理
  FOR user_record IN
    SELECT 
      u.id,
      u.name,
      COALESCE(SUM(ra.reward_amount), 0) as unclaimed_rewards
    FROM users u
    LEFT JOIN reward_applications ra ON u.id = ra.user_id 
      AND ra.status = 'pending'
      AND ra.created_at < NOW() - INTERVAL '7 days'
    WHERE u.is_admin = false
    GROUP BY u.id, u.name
    HAVING COALESCE(SUM(ra.reward_amount), 0) > 0
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

-- 4. 週次統合バッチ実行関数
CREATE OR REPLACE FUNCTION execute_weekly_batch()
RETURNS TABLE(
  batch_summary TEXT
) AS $$
DECLARE
  rank_result RECORD;
  compound_result RECORD;
  summary_text TEXT;
BEGIN
  -- ランク更新実行
  SELECT * INTO rank_result FROM execute_weekly_rank_update();
  
  -- 複利処理実行
  SELECT * INTO compound_result FROM execute_weekly_compound_processing();
  
  -- サマリー作成
  summary_text := format(
    'Weekly batch completed: Rank updates: %s users (%s changes), Compound processing: %s users ($%s total)',
    rank_result.updated_users,
    rank_result.rank_changes,
    compound_result.processed_users,
    compound_result.total_compound_amount
  );
  
  RETURN QUERY SELECT summary_text;
END;
$$ LANGUAGE plpgsql;

-- 5. バッチ実行履歴確認関数
CREATE OR REPLACE FUNCTION get_batch_execution_history(limit_count INTEGER DEFAULT 10)
RETURNS TABLE(
  batch_type VARCHAR,
  execution_date TIMESTAMP WITH TIME ZONE,
  status VARCHAR,
  execution_time INTERVAL,
  affected_records INTEGER,
  details JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    beh.batch_type,
    beh.execution_date,
    beh.status,
    beh.end_time - beh.start_time as execution_time,
    beh.affected_records,
    beh.execution_details
  FROM batch_execution_history beh
  ORDER BY beh.execution_date DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- 6. テスト実行
SELECT 'Testing weekly batch system...' as status;

-- ランク更新テスト
SELECT * FROM execute_weekly_rank_update();

-- 複利処理テスト
SELECT * FROM execute_weekly_compound_processing();

-- 統合バッチテスト
SELECT * FROM execute_weekly_batch();

-- 実行履歴確認
SELECT * FROM get_batch_execution_history(5);

SELECT 'Weekly batch automation system created successfully' as status;
