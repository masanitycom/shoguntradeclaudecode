-- determine_user_rank関数の呼び出し方法を修正

-- 1. 週次ランク更新バッチ関数（修正版）
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
  rank_result RECORD;
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
    
    -- 新しいランクを判定（正しい関数呼び出し）
    SELECT * INTO rank_result
    FROM determine_user_rank(user_record.id);
    
    -- ランクが変更された場合
    IF current_rank != rank_result.qualified_rank_level THEN
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
      ) VALUES (
        user_record.id,
        rank_result.qualified_rank_level,
        rank_result.rank_name,
        rank_result.organization_volume,
        rank_result.max_line_volume,
        rank_result.other_lines_volume,
        CURRENT_DATE,
        true,
        (SELECT COALESCE(SUM(purchase_price), 0) FROM user_nfts WHERE user_id = user_record.id AND is_active = true),
        rank_result.organization_volume
      );
      
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

-- 2. テスト実行
SELECT 'Testing corrected weekly batch system...' as status;

-- ランク更新テスト
SELECT * FROM execute_weekly_rank_update();

-- 複利処理テスト  
SELECT * FROM execute_weekly_compound_processing();

-- 統合バッチテスト
SELECT * FROM execute_weekly_batch();

-- 実行履歴確認
SELECT * FROM get_batch_execution_history(5);

SELECT 'Corrected weekly batch automation system completed' as status;
