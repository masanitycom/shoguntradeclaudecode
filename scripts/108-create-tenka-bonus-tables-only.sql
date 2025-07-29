-- 天下統一ボーナス関連テーブルのみ作成

-- 1. 天下統一ボーナス分配テーブル
CREATE TABLE IF NOT EXISTS tenka_bonus_distributions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  week_start_date DATE NOT NULL,
  week_end_date DATE NOT NULL,
  total_company_profit DECIMAL(15,2) NOT NULL,
  bonus_pool DECIMAL(15,2) NOT NULL, -- 会社利益の20%
  total_distributed DECIMAL(15,2) DEFAULT 0,
  distribution_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. 個別ユーザーへの天下統一ボーナス記録
CREATE TABLE IF NOT EXISTS user_tenka_bonuses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  distribution_id UUID REFERENCES tenka_bonus_distributions(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  rank_level INTEGER NOT NULL,
  rank_name VARCHAR(50) NOT NULL,
  bonus_percentage DECIMAL(5,2) NOT NULL,
  bonus_amount DECIMAL(15,2) NOT NULL,
  is_applied_to_300_cap BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. インデックス作成
CREATE INDEX IF NOT EXISTS idx_tenka_distributions_week ON tenka_bonus_distributions(week_start_date, week_end_date);
CREATE INDEX IF NOT EXISTS idx_user_tenka_bonuses_user ON user_tenka_bonuses(user_id);
CREATE INDEX IF NOT EXISTS idx_user_tenka_bonuses_distribution ON user_tenka_bonuses(distribution_id);

-- 4. weekly_profitsテーブルに天下統一ボーナス関連カラムを追加
ALTER TABLE weekly_profits 
ADD COLUMN IF NOT EXISTS tenka_bonus_distributed BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS tenka_distribution_id UUID;

-- 5. 外部キー制約を追加（テーブル作成後）
ALTER TABLE weekly_profits 
ADD CONSTRAINT fk_weekly_profits_tenka_distribution 
FOREIGN KEY (tenka_distribution_id) REFERENCES tenka_bonus_distributions(id);

-- 6. 確認
SELECT 'Tenka bonus tables created successfully' as status;

-- 7. テーブル一覧確認
SELECT table_name 
FROM information_schema.tables 
WHERE table_name IN ('tenka_bonus_distributions', 'user_tenka_bonuses', 'weekly_profits')
ORDER BY table_name;
