-- mlm_ranksテーブルの修正とuser_rank_historyテーブルの作成

-- 1. mlm_ranksテーブルを正しい構造で再作成
DROP TABLE IF EXISTS mlm_ranks CASCADE;

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

-- 2. ランクデータの挿入（仕様書通り）
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

-- 3. user_rank_historyテーブルを作成
DROP TABLE IF EXISTS user_rank_history CASCADE;

CREATE TABLE user_rank_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  rank_level INTEGER REFERENCES mlm_ranks(rank_level),
  organization_volume DECIMAL(15,2) DEFAULT 0,
  max_line_volume DECIMAL(15,2) DEFAULT 0,
  other_lines_volume DECIMAL(15,2) DEFAULT 0,
  qualified_date DATE DEFAULT CURRENT_DATE,
  is_current BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. インデックス作成
CREATE INDEX idx_user_rank_history_user_current ON user_rank_history(user_id, is_current);
CREATE INDEX idx_user_rank_history_rank_level ON user_rank_history(rank_level);

-- 5. 組織ボリューム計算関数を再作成
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

-- 6. ランク判定関数を再作成
CREATE OR REPLACE FUNCTION determine_user_rank(user_id_param UUID)
RETURNS TABLE(
  qualified_rank_level INTEGER,
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
    WHERE rank_level > 0 
    ORDER BY rank_level DESC
  LOOP
    -- NFT価値チェック
    IF user_nft_value >= rank_record.required_nft_value THEN
      -- 足軽の場合は組織ボリューム1000以上が必要
      IF rank_record.rank_level = 1 THEN
        IF org_volume >= 1000 THEN
          qualified_rank := rank_record.rank_level;
          EXIT;
        END IF;
      -- その他のランクは組織条件をチェック
      ELSIF rank_record.max_organization_volume IS NOT NULL 
        AND rank_record.other_lines_volume IS NOT NULL THEN
        IF max_line >= rank_record.max_organization_volume 
          AND other_lines >= rank_record.other_lines_volume THEN
          qualified_rank := rank_record.rank_level;
          EXIT;
        END IF;
      END IF;
    END IF;
  END LOOP;
  
  -- 結果を返す
  SELECT mr.rank_name INTO rank_record.rank_name
  FROM mlm_ranks mr WHERE mr.rank_level = qualified_rank;
  
  RETURN QUERY SELECT 
    qualified_rank,
    COALESCE(rank_record.rank_name, 'なし'),
    org_volume,
    max_line,
    other_lines;
END;
$$ LANGUAGE plpgsql;

-- 7. テストユーザーにランクを付与
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
      is_current
    ) VALUES (
      test_user_id,
      1, -- 足軽
      1500,
      800,
      700,
      CURRENT_DATE,
      true
    );
    
    RAISE NOTICE 'Assigned 足軽 rank to user: %', test_user_id;
  ELSE
    RAISE NOTICE 'User ohtakiyo not found';
  END IF;
END $$;

-- 8. 確認
SELECT 'MLM system recreated successfully' as status;

-- 9. 作成されたテーブルとデータを確認
SELECT 'MLM Ranks:' as info;
SELECT rank_level, rank_name, required_nft_value, bonus_percentage FROM mlm_ranks ORDER BY rank_level;

SELECT 'Current Rank Holders:' as info;
SELECT 
  u.name,
  u.user_id,
  mr.rank_name,
  urh.organization_volume,
  urh.qualified_date
FROM user_rank_history urh
JOIN users u ON urh.user_id = u.id
JOIN mlm_ranks mr ON urh.rank_level = mr.rank_level
WHERE urh.is_current = true
ORDER BY urh.rank_level DESC;
