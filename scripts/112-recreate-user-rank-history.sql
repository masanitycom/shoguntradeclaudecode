-- user_rank_historyテーブルの再作成

-- 1. 既存テーブルがあれば削除
DROP TABLE IF EXISTS user_rank_history CASCADE;

-- 2. user_rank_historyテーブルを作成
CREATE TABLE user_rank_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  rank_level INTEGER REFERENCES mlm_ranks(rank_level),
  organization_volume DECIMAL(15,2) DEFAULT 0,
  max_line_volume DECIMAL(15,2) DEFAULT 0,
  other_lines_volume DECIMAL(15,2) DEFAULT 0,
  qualified_date DATE DEFAULT CURRENT_DATE,
  is_current BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  -- 追加フィールド（テスト用）
  achieved_date DATE DEFAULT CURRENT_DATE,
  nft_value_at_time DECIMAL(15,2) DEFAULT 0,
  organization_volume_at_time DECIMAL(15,2) DEFAULT 0
);

-- 3. インデックス作成
CREATE INDEX idx_user_rank_history_user_current ON user_rank_history(user_id, is_current);
CREATE INDEX idx_user_rank_history_rank_level ON user_rank_history(rank_level);

-- 4. テストユーザーにランクを付与
DO $$
DECLARE
  test_user_id UUID;
BEGIN
  -- ohtakiyoユーザーを検索
  SELECT id INTO test_user_id FROM users WHERE user_id = 'ohtakiyo' LIMIT 1;
  
  IF test_user_id IS NOT NULL THEN
    -- 足軽ランクを付与
    INSERT INTO user_rank_history (
      user_id,
      rank_level,
      organization_volume,
      max_line_volume,
      other_lines_volume,
      qualified_date,
      is_current,
      achieved_date,
      nft_value_at_time,
      organization_volume_at_time
    ) VALUES (
      test_user_id,
      1, -- 足軽
      1500,
      800,
      700,
      CURRENT_DATE,
      true,
      CURRENT_DATE,
      1000,
      1500
    );
    
    RAISE NOTICE 'Assigned 足軽 rank to user: %', test_user_id;
  ELSE
    RAISE NOTICE 'User ohtakiyo not found';
  END IF;
END $$;

-- 5. 確認
SELECT 'User rank history table recreated successfully' as status;

-- 6. 現在のランク保有者を確認
SELECT 
  u.name,
  u.user_id,
  mr.rank_name,
  urh.organization_volume,
  urh.qualified_date,
  urh.is_current
FROM user_rank_history urh
JOIN users u ON urh.user_id = u.id
JOIN mlm_ranks mr ON urh.rank_level = mr.rank_level
WHERE urh.is_current = true
ORDER BY urh.rank_level DESC;
