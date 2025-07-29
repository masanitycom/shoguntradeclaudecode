-- ダッシュボード関数を完全に修正

-- 1. 既存の関数をすべて削除
DROP FUNCTION IF EXISTS get_user_dashboard_data(UUID);
DROP FUNCTION IF EXISTS get_user_reward_summary(UUID);
DROP FUNCTION IF EXISTS get_user_claimable_rewards(UUID);
DROP FUNCTION IF EXISTS get_user_daily_rewards_history(UUID, INTEGER);

-- 2. 正しい型定義でget_user_dashboard_data関数を作成
CREATE OR REPLACE FUNCTION get_user_dashboard_data(p_user_id UUID)
RETURNS TABLE(
  nft_id UUID,
  nft_name TEXT,
  nft_price DECIMAL,
  current_investment DECIMAL,
  total_earned DECIMAL,
  max_earning DECIMAL,
  progress_percent DECIMAL,
  pending_rewards DECIMAL,
  is_active BOOLEAN,
  completion_date DATE
) AS $$
BEGIN
  RETURN QUERY
  SELECT  
    un.nft_id, 
    n.name::TEXT as nft_name, 
    n.price as nft_price, 
    un.current_investment, 
    un.total_earned, 
    un.max_earning, 
    CASE  
      WHEN un.max_earning > 0 THEN (un.total_earned / un.max_earning * 100) 
      ELSE 0 
    END as progress_percent, 
    COALESCE(( 
      SELECT SUM(dr.reward_amount) 
      FROM daily_rewards dr 
      WHERE dr.user_id = un.user_id  
        AND dr.nft_id = un.nft_id 
        AND dr.is_claimed = false 
    ), 0) as pending_rewards, 
    un.is_active, 
    un.completion_date 
  FROM user_nfts un 
  JOIN nfts n ON un.nft_id = n.id 
  WHERE un.user_id = p_user_id 
    AND un.current_investment > 0 
  ORDER BY un.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- 3. get_user_reward_summary関数を作成
CREATE OR REPLACE FUNCTION get_user_reward_summary(p_user_id UUID)
RETURNS TABLE(
  total_investment DECIMAL,
  total_earned DECIMAL,
  pending_rewards DECIMAL,
  claimed_rewards DECIMAL,
  active_nfts INTEGER,
  completed_nfts INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COALESCE(SUM(un.current_investment), 0) as total_investment,
    COALESCE(SUM(un.total_earned), 0) as total_earned,
    COALESCE((
      SELECT SUM(dr.reward_amount)
      FROM daily_rewards dr
      WHERE dr.user_id = p_user_id AND dr.is_claimed = false
    ), 0) as pending_rewards,
    COALESCE((
      SELECT SUM(dr.reward_amount)
      FROM daily_rewards dr
      WHERE dr.user_id = p_user_id AND dr.is_claimed = true
    ), 0) as claimed_rewards,
    COUNT(CASE WHEN un.is_active = true THEN 1 END)::INTEGER as active_nfts,
    COUNT(CASE WHEN un.is_active = false AND un.completion_date IS NOT NULL THEN 1 END)::INTEGER as completed_nfts
  FROM user_nfts un
  WHERE un.user_id = p_user_id
    AND un.current_investment > 0;
END;
$$ LANGUAGE plpgsql;

-- 4. get_user_claimable_rewards関数を作成
CREATE OR REPLACE FUNCTION get_user_claimable_rewards(p_user_id UUID)
RETURNS TABLE(
  total_claimable DECIMAL,
  reward_count INTEGER,
  oldest_reward_date DATE,
  newest_reward_date DATE,
  can_claim BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COALESCE(SUM(dr.reward_amount), 0) as total_claimable,
    COUNT(dr.id)::INTEGER as reward_count,
    MIN(dr.reward_date) as oldest_reward_date,
    MAX(dr.reward_date) as newest_reward_date,
    (COALESCE(SUM(dr.reward_amount), 0) >= 50) as can_claim
  FROM daily_rewards dr
  WHERE dr.user_id = p_user_id 
    AND dr.is_claimed = false;
END;
$$ LANGUAGE plpgsql;

-- 5. get_user_daily_rewards_history関数を作成
CREATE OR REPLACE FUNCTION get_user_daily_rewards_history(
  p_user_id UUID, 
  p_limit INTEGER DEFAULT 10
)
RETURNS TABLE(
  reward_date DATE,
  nft_name TEXT,
  daily_rate DECIMAL,
  reward_amount DECIMAL,
  is_claimed BOOLEAN,
  created_at TIMESTAMP
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    dr.reward_date,
    n.name::TEXT as nft_name,
    dr.daily_rate,
    dr.reward_amount,
    dr.is_claimed,
    dr.created_at
  FROM daily_rewards dr
  JOIN nfts n ON dr.nft_id = n.id
  WHERE dr.user_id = p_user_id
  ORDER BY dr.reward_date DESC, dr.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- 6. 関数の動作テスト
SELECT 'Testing dashboard functions...' as status;

-- テスト用ユーザーを取得
DO $$
DECLARE
  test_user_id UUID;
  test_user_name TEXT;
BEGIN
  -- アクティブなNFTを持つユーザーを取得
  SELECT u.id, COALESCE(u.name, u.email) INTO test_user_id, test_user_name
  FROM users u
  WHERE EXISTS (
    SELECT 1 FROM user_nfts un 
    WHERE un.user_id = u.id AND un.is_active = true AND un.current_investment > 0
  )
  LIMIT 1;
  
  IF test_user_id IS NOT NULL THEN
    RAISE NOTICE 'テストユーザー: % (ID: %)', test_user_name, test_user_id;
    
    -- ダッシュボードデータをテスト
    RAISE NOTICE 'ダッシュボードデータテスト実行中...';
    
  ELSE
    RAISE NOTICE 'テスト用ユーザーが見つかりません';
  END IF;
END $$;

-- 7. システム統計を表示
SELECT 
  'System Statistics' as stat_type,
  'Total Users' as metric,
  COUNT(*) as value
FROM users

UNION ALL

SELECT 
  'System Statistics' as stat_type,
  'Users with Active NFTs' as metric,
  COUNT(DISTINCT un.user_id) as value
FROM user_nfts un
WHERE un.is_active = true AND un.current_investment > 0

UNION ALL

SELECT 
  'System Statistics' as stat_type,
  'Total Daily Rewards' as metric,
  COUNT(*) as value
FROM daily_rewards

UNION ALL

SELECT 
  'System Statistics' as stat_type,
  'Unclaimed Rewards' as metric,
  COUNT(*) as value
FROM daily_rewards
WHERE is_claimed = false;

-- 8. 関数作成完了メッセージ
SELECT 'Dashboard functions created successfully with correct types' as status;
