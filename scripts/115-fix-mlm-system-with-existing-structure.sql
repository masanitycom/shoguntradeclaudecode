-- 既存のmlm_ranksテーブル構造に合わせてMLMシステムを修正

-- 1. 既存のmlm_ranksテーブルにデータを挿入
DELETE FROM mlm_ranks; -- 既存データをクリア

INSERT INTO mlm_ranks (rank_name, rank_name_en, required_investment, max_line_requirement, other_lines_requirement, distribution_rate, bonus_rate, rank_order) VALUES
('なし', 'None', 0, 0, 0, 0, 0, 0),
('足軽', 'Ashigaru', 1000, 0, 1000, 45, 45, 1),
('武将', 'Busho', 1000, 3000, 1500, 25, 25, 2),
('代官', 'Daikan', 1000, 5000, 2500, 10, 10, 3),
('奉行', 'Bugyo', 1000, 10000, 5000, 6, 6, 4),
('老中', 'Roju', 1000, 50000, 25000, 5, 5, 5),
('大老', 'Tairo', 1000, 100000, 50000, 4, 4, 6),
('大名', 'Daimyo', 1000, 300000, 150000, 3, 3, 7),
('将軍', 'Shogun', 1000, 600000, 500000, 2, 2, 8);

-- 2. user_rank_historyテーブルを作成（既存構造に合わせて）
DROP TABLE IF EXISTS user_rank_history CASCADE;

CREATE TABLE user_rank_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  rank_order INTEGER REFERENCES mlm_ranks(rank_order),
  rank_name VARCHAR(50) NOT NULL,
  organization_volume DECIMAL(15,2) DEFAULT 0,
  max_line_volume DECIMAL(15,2) DEFAULT 0,
  other_lines_volume DECIMAL(15,2) DEFAULT 0,
  qualified_date DATE DEFAULT CURRENT_DATE,
  is_current BOOLEAN DEFAULT true,
  nft_value_at_time DECIMAL(15,2) DEFAULT 0,
  organization_volume_at_time DECIMAL(15,2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. インデックス作成
CREATE INDEX idx_user_rank_history_user_current ON user_rank_history(user_id, is_current);
CREATE INDEX idx_user_rank_history_rank_order ON user_rank_history(rank_order);

-- 4. 組織ボリューム計算関数を既存構造に合わせて修正
CREATE OR REPLACE FUNCTION calculate_organization_volume(user_id_param UUID)
RETURNS TABLE(
  total_volume DECIMAL,
  max_line_volume DECIMAL,
  other_lines_volume DECIMAL,
  direct_referrals_count INTEGER
) AS $$
BEGIN
  RETURN QUERY
  WITH RECURSIVE organization_tree AS (
    -- 直接紹介者
    SELECT 
      u.id,
      u.referrer_id,
      COALESCE(un.current_investment, 0) as investment,
      1 as level,
      u.referrer_id as root_referrer
    FROM users u
    LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
    WHERE u.referrer_id = user_id_param
    
    UNION ALL
    
    -- 間接紹介者（再帰）
    SELECT 
      u.id,
      u.referrer_id,
      COALESCE(un.current_investment, 0) as investment,
      ot.level + 1,
      ot.root_referrer
    FROM users u
    LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
    JOIN organization_tree ot ON u.referrer_id = ot.id
    WHERE ot.level < 8  -- 8段階まで
  ),
  line_volumes AS (
    SELECT 
      root_referrer,
      SUM(investment) as line_volume
    FROM organization_tree
    GROUP BY root_referrer
  ),
  volume_stats AS (
    SELECT 
      COALESCE(SUM(line_volume), 0) as total_vol,
      COALESCE(MAX(line_volume), 0) as max_line_vol,
      COALESCE(SUM(line_volume) - MAX(line_volume), 0) as other_lines_vol,
      COUNT(DISTINCT root_referrer) as direct_count
    FROM line_volumes
  )
  SELECT 
    vs.total_vol,
    vs.max_line_vol,
    vs.other_lines_vol,
    vs.direct_count::INTEGER
  FROM volume_stats vs;
END;
$$ LANGUAGE plpgsql;

-- 5. ランク判定関数を既存構造に合わせて修正
CREATE OR REPLACE FUNCTION determine_user_rank(user_id_param UUID)
RETURNS TABLE(
  qualified_rank_order INTEGER,
  rank_name VARCHAR,
  organization_volume DECIMAL,
  max_line_volume DECIMAL,
  other_lines_volume DECIMAL
) AS $$
DECLARE
  user_nft_value DECIMAL := 0;
  org_volume DECIMAL := 0;
  max_line DECIMAL := 0;
  other_lines DECIMAL := 0;
  direct_count INTEGER := 0;
  qualified_rank INTEGER := 0;
  rank_record RECORD;
BEGIN
  -- ユーザーのNFT価値を取得
  SELECT COALESCE(SUM(un.current_investment), 0) INTO user_nft_value
  FROM user_nfts un
  WHERE un.user_id = user_id_param AND un.is_active = true;
  
  -- 組織ボリュームを計算
  SELECT * INTO org_volume, max_line, other_lines, direct_count
  FROM calculate_organization_volume(user_id_param);
  
  -- ランク判定（高いランクから順にチェック）
  FOR rank_record IN 
    SELECT * FROM mlm_ranks 
    WHERE rank_order > 0 
    ORDER BY rank_order DESC
  LOOP
    -- NFT価値チェック
    IF user_nft_value >= rank_record.required_investment THEN
      -- 足軽の場合は組織ボリューム1000以上が必要
      IF rank_record.rank_order = 1 THEN
        IF org_volume >= rank_record.other_lines_requirement THEN
          qualified_rank := rank_record.rank_order;
          EXIT;
        END IF;
      -- その他のランクは組織条件をチェック
      ELSIF rank_record.max_line_requirement > 0 
        AND rank_record.other_lines_requirement > 0 THEN
        IF max_line >= rank_record.max_line_requirement 
          AND other_lines >= rank_record.other_lines_requirement THEN
          qualified_rank := rank_record.rank_order;
          EXIT;
        END IF;
      END IF;
    END IF;
  END LOOP;
  
  -- 結果を返す
  SELECT mr.rank_name INTO rank_record.rank_name
  FROM mlm_ranks mr WHERE mr.rank_order = qualified_rank;
  
  RETURN QUERY SELECT 
    qualified_rank,
    COALESCE(rank_record.rank_name, 'なし'),
    org_volume,
    max_line,
    other_lines;
END;
$$ LANGUAGE plpgsql;

-- 6. 全ユーザーランク更新関数を既存構造に合わせて修正
CREATE OR REPLACE FUNCTION update_all_user_ranks()
RETURNS TABLE(
  updated_users INTEGER,
  rank_changes INTEGER
) AS $$
DECLARE
  user_record RECORD;
  rank_result RECORD;
  updated_count INTEGER := 0;
  changed_count INTEGER := 0;
  current_rank INTEGER;
BEGIN
  -- 全ユーザーをループ
  FOR user_record IN 
    SELECT id, name FROM users WHERE is_active = true
  LOOP
    -- 現在のランクを取得
    SELECT rank_order INTO current_rank
    FROM user_rank_history 
    WHERE user_id = user_record.id AND is_current = true;
    
    -- ランクを判定
    SELECT * INTO rank_result
    FROM determine_user_rank(user_record.id);
    
    -- ランクが変更された場合
    IF COALESCE(current_rank, 0) != rank_result.qualified_rank_order THEN
      -- 既存のランク履歴を無効化
      UPDATE user_rank_history 
      SET is_current = false 
      WHERE user_id = user_record.id;
      
      -- 新しいランク履歴を作成
      INSERT INTO user_rank_history (
        user_id,
        rank_order,
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
        rank_result.qualified_rank_order,
        rank_result.rank_name,
        rank_result.organization_volume,
        rank_result.max_line_volume,
        rank_result.other_lines_volume,
        CURRENT_DATE,
        true,
        (SELECT COALESCE(SUM(current_investment), 0) FROM user_nfts WHERE user_id = user_record.id AND is_active = true),
        rank_result.organization_volume
      );
      
      changed_count := changed_count + 1;
    END IF;
    
    updated_count := updated_count + 1;
  END LOOP;
  
  RETURN QUERY SELECT updated_count, changed_count;
END;
$$ LANGUAGE plpgsql;

-- 7. 天下統一ボーナス関数を既存構造に合わせて修正
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
  SELECT COALESCE(SUM(mr.distribution_rate), 0) INTO total_percentage
  FROM user_rank_history urh
  JOIN mlm_ranks mr ON urh.rank_order = mr.rank_order
  WHERE urh.is_current = true AND urh.rank_order > 0;
  
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
      urh.rank_order,
      mr.rank_name,
      mr.distribution_rate,
      u.name as user_name
    FROM user_rank_history urh
    JOIN mlm_ranks mr ON urh.rank_order = mr.rank_order
    JOIN users u ON urh.user_id = u.id
    WHERE urh.is_current = true AND urh.rank_order > 0
  LOOP
    -- 個別ボーナス額を計算（分配率に応じて按分）
    bonus_amount := bonus_pool * (user_record.distribution_rate / total_percentage);
    
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
      user_record.rank_order,
      user_record.rank_name,
      user_record.distribution_rate,
      bonus_amount
    );
    
    total_distributed := total_distributed + bonus_amount;
    beneficiary_count := beneficiary_count + 1;
  END LOOP;
  
  -- 分配記録を更新
  UPDATE tenka_bonus_distributions 
  SET total_distributed = total_distributed
  WHERE id = distribution_record_id;
  
  -- 結果を返す
  RETURN QUERY SELECT 
    distribution_record_id,
    bonus_pool,
    total_distributed,
    beneficiary_count;
END;
$$ LANGUAGE plpgsql;

-- 8. テストユーザーにランクを付与
DO $$
DECLARE
  test_user_id UUID;
BEGIN
  -- ohtakiyoユーザーを検索
  SELECT id INTO test_user_id FROM users WHERE user_id = 'ohtakiyo' LIMIT 1;
  
  IF test_user_id IS NOT NULL THEN
    -- 既存のランク履歴を削除
    DELETE FROM user_rank_history WHERE user_id = test_user_id;
    
    -- 足軽ランクを付与
    INSERT INTO user_rank_history (
      user_id,
      rank_order,
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

-- 9. 確認
SELECT 'MLM system fixed with existing structure' as status;

-- 10. 作成されたデータを確認
SELECT 'MLM Ranks:' as info;
SELECT rank_order, rank_name, required_investment, distribution_rate FROM mlm_ranks ORDER BY rank_order;

SELECT 'Current Rank Holders:' as info;
SELECT 
  u.name,
  u.user_id,
  urh.rank_name,
  urh.organization_volume,
  urh.qualified_date
FROM user_rank_history urh
JOIN users u ON urh.user_id = u.id
WHERE urh.is_current = true
ORDER BY urh.rank_order DESC;
