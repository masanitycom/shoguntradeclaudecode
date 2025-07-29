-- MLMランクステーブルの構造確認と修正

-- 1. 既存テーブル構造を確認
SELECT 
  column_name, 
  data_type, 
  is_nullable, 
  column_default
FROM information_schema.columns 
WHERE table_name = 'mlm_ranks' 
ORDER BY ordinal_position;

-- 2. 既存テーブルがあれば削除
DROP TABLE IF EXISTS user_rank_history CASCADE;
DROP TABLE IF EXISTS mlm_ranks CASCADE;

-- 3. 正しい構造でMLMランクステーブルを作成
CREATE TABLE mlm_ranks (
  id SERIAL PRIMARY KEY,
  rank_level INTEGER UNIQUE NOT NULL,
  rank_name VARCHAR(50) NOT NULL,
  required_nft_value DECIMAL(15,2) NOT NULL,
  max_organization_volume DECIMAL(15,2),
  other_lines_volume DECIMAL(15,2),
  bonus_percentage DECIMAL(5,2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. ランクデータの挿入
INSERT INTO mlm_ranks (rank_level, rank_name, required_nft_value, max_organization_volume, other_lines_volume, bonus_percentage) VALUES
(0, 'なし', 0, NULL, NULL, 0),
(1, '足軽', 1000, NULL, NULL, 45),
(2, '武将', 1000, 3000, 1500, 25),
(3, '代官', 1000, 5000, 2500, 10),
(4, '奉行', 1000, 10000, 5000, 6),
(5, '老中', 1000, 50000, 25000, 5),
(6, '大老', 1000, 100000, 50000, 4),
(7, '大名', 1000, 300000, 150000, 3),
(8, '将軍', 1000, 600000, 500000, 2);

-- 5. ユーザーランク履歴テーブル
CREATE TABLE user_rank_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  rank_level INTEGER REFERENCES mlm_ranks(rank_level),
  organization_volume DECIMAL(15,2) DEFAULT 0,
  max_line_volume DECIMAL(15,2) DEFAULT 0,
  other_lines_volume DECIMAL(15,2) DEFAULT 0,
  qualified_date DATE,
  is_current BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. インデックス作成
CREATE INDEX idx_user_rank_history_user_current ON user_rank_history(user_id, is_current);
CREATE INDEX idx_user_rank_history_rank_level ON user_rank_history(rank_level);

-- 7. 確認
SELECT 'MLM ranks table structure fixed' as status;
SELECT * FROM mlm_ranks ORDER BY rank_level;
