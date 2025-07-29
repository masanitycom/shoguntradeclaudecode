-- ユーザーダッシュボード表示の修正

-- 1. 既存の関数を削除
DROP FUNCTION IF EXISTS get_user_dashboard_data(UUID);
DROP FUNCTION IF EXISTS get_user_pending_rewards(UUID);
DROP FUNCTION IF EXISTS get_user_total_investment(UUID);
DROP FUNCTION IF EXISTS get_user_total_earned(UUID);
DROP FUNCTION IF EXISTS get_user_reward_summary(UUID);
DROP FUNCTION IF EXISTS get_user_daily_rewards_history(UUID, INTEGER);
DROP FUNCTION IF EXISTS get_user_claimable_rewards(UUID);

-- 2. 保留中報酬の計算関数を作成
CREATE OR REPLACE FUNCTION get_user_pending_rewards(p_user_id UUID)
RETURNS TABLE(
  total_pending DECIMAL,
  daily_rewards DECIMAL,
  tenka_bonus DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(SUM(dr.reward_amount), 0) as total_pending,
    COALESCE(SUM(dr.reward_amount), 0) as daily_rewards,
    0::DECIMAL as tenka_bonus -- 天下統一ボーナスは後で実装
  FROM daily_rewards dr
  WHERE dr.user_id = p_user_id
    AND dr.is_claimed = false;
END;
$$ LANGUAGE plpgsql;

-- 3. ユーザーの総投資額計算関数を作成
CREATE OR REPLACE FUNCTION get_user_total_investment(p_user_id UUID)
RETURNS DECIMAL AS $$
DECLARE
  total_investment DECIMAL := 0;
BEGIN
  SELECT COALESCE(SUM(n.price), 0) INTO total_investment
  FROM user_nfts un
  JOIN nfts n ON un.nft_id = n.id
  WHERE un.user_id = p_user_id
    AND un.is_active = true;
    
  RETURN total_investment;
END;
$$ LANGUAGE plpgsql;

-- 4. ユーザーの総獲得額計算関数を作成
CREATE OR REPLACE FUNCTION get_user_total_earned(p_user_id UUID)
RETURNS DECIMAL AS $$
DECLARE
  total_earned DECIMAL := 0;
BEGIN
  SELECT COALESCE(SUM(un.total_earned), 0) INTO total_earned
  FROM user_nfts un
  WHERE un.user_id = p_user_id
    AND un.is_active = true;
    
  RETURN total_earned;
END;
$$ LANGUAGE plpgsql;

-- 5. ユーザーダッシュボード用の関数を作成
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
    n.name as nft_name,
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

-- 6. ユーザー報酬サマリー関数を作成
CREATE OR REPLACE FUNCTION get_user_reward_summary(p_user_id UUID)
RETURNS TABLE(
  total_investment DECIMAL,
  total_earned DECIMAL,
  pending_rewards DECIMAL,
  active_nfts INTEGER,
  completed_nfts INTEGER,
  total_progress_percent DECIMAL
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
    COUNT(CASE WHEN un.is_active THEN 1 END)::INTEGER as active_nfts,
    COUNT(CASE WHEN NOT un.is_active AND un.completion_date IS NOT NULL THEN 1 END)::INTEGER as completed_nfts,
    CASE 
      WHEN SUM(un.max_earning) > 0 THEN (SUM(un.total_earned) / SUM(un.max_earning) * 100)
      ELSE 0
    END as total_progress_percent
  FROM user_nfts un
  WHERE un.user_id = p_user_id
    AND un.current_investment > 0;
END;
$$ LANGUAGE plpgsql;

-- 7. 日利履歴取得関数を作成
CREATE OR REPLACE FUNCTION get_user_daily_rewards_history(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 30
)
RETURNS TABLE(
  reward_date DATE,
  nft_name TEXT,
  reward_amount DECIMAL,
  daily_rate DECIMAL,
  is_claimed BOOLEAN,
  created_at TIMESTAMP
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    dr.reward_date,
    n.name as nft_name,
    dr.reward_amount,
    dr.daily_rate,
    dr.is_claimed,
    dr.created_at
  FROM daily_rewards dr
  JOIN nfts n ON dr.nft_id = n.id
  WHERE dr.user_id = p_user_id
  ORDER BY dr.reward_date DESC, dr.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- 8. 報酬申請可能額取得関数を作成
CREATE OR REPLACE FUNCTION get_user_claimable_rewards(p_user_id UUID)
RETURNS TABLE(
  total_claimable DECIMAL,
  reward_count INTEGER,
  oldest_reward_date DATE,
  newest_reward_date DATE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(SUM(dr.reward_amount), 0) as total_claimable,
    COUNT(dr.id)::INTEGER as reward_count,
    MIN(dr.reward_date) as oldest_reward_date,
    MAX(dr.reward_date) as newest_reward_date
  FROM daily_rewards dr
  WHERE dr.user_id = p_user_id 
    AND dr.is_claimed = false
    AND dr.reward_amount > 0;
END;
$$ LANGUAGE plpgsql;

-- 9. 関数作成完了の確認
SELECT 'Dashboard functions created successfully' as status;
