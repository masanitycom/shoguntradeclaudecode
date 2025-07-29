-- MLMランク計算関数の作成

-- 1. 組織ボリューム計算関数
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

-- 2. ランク判定関数
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

-- 3. 全ユーザーのランク更新関数
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
  -- 既存の現在ランクを非アクティブに
  UPDATE user_rank_history SET is_current = false WHERE is_current = true;
  
  -- 全ユーザーのランクを更新
  FOR user_record IN 
    SELECT id FROM users WHERE is_admin = false
  LOOP
    -- 現在のランクを取得
    SELECT COALESCE(rank_level, 0) INTO current_rank
    FROM user_rank_history 
    WHERE user_id = user_record.id AND is_current = true
    ORDER BY created_at DESC LIMIT 1;
    
    -- 新しいランクを判定
    SELECT * INTO rank_result
    FROM determine_user_rank(user_record.id);
    
    -- ランク履歴に記録
    INSERT INTO user_rank_history (
      user_id, 
      rank_level, 
      organization_volume, 
      max_line_volume, 
      other_lines_volume,
      qualified_date,
      is_current
    ) VALUES (
      user_record.id,
      rank_result.qualified_rank_level,
      rank_result.organization_volume,
      rank_result.max_line_volume,
      rank_result.other_lines_volume,
      CURRENT_DATE,
      true
    );
    
    updated_count := updated_count + 1;
    
    -- ランクが変更された場合
    IF COALESCE(current_rank, 0) != rank_result.qualified_rank_level THEN
      changed_count := changed_count + 1;
    END IF;
  END LOOP;
  
  RETURN QUERY SELECT updated_count, changed_count;
END;
$$ LANGUAGE plpgsql;

-- 4. テスト実行
SELECT 'MLM functions created successfully' as status;
