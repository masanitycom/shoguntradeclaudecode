-- 実際の報酬計算用関数を作成

-- 1. ユーザーの未申請報酬を計算する関数
CREATE OR REPLACE FUNCTION get_user_pending_rewards(user_id_param UUID)
RETURNS TABLE(
  total_amount DECIMAL,
  daily_rewards DECIMAL,
  tenka_bonus DECIMAL,
  last_application_date DATE
) AS $$
BEGIN
  RETURN QUERY
  WITH user_rewards AS (
    -- 日利報酬の合計（未申請分）
    SELECT 
      COALESCE(SUM(dr.reward_amount), 0) as daily_total
    FROM daily_rewards dr
    JOIN user_nfts un ON dr.user_nft_id = un.id
    WHERE un.user_id = user_id_param
      AND dr.is_claimed = false
  ),
  user_tenka AS (
    -- 天下統一ボーナス（未申請分）
    SELECT 
      COALESCE(SUM(tb.bonus_amount), 0) as tenka_total
    FROM tenka_bonuses tb
    WHERE tb.user_id = user_id_param
      AND tb.is_claimed = false
  ),
  last_app AS (
    -- 最後の申請日
    SELECT 
      MAX(ra.created_at::date) as last_date
    FROM reward_applications ra
    WHERE ra.user_id = user_id_param
      AND ra.status = 'APPROVED'
  )
  SELECT 
    ur.daily_total + ut.tenka_total as total_amount,
    ur.daily_total as daily_rewards,
    ut.tenka_total as tenka_bonus,
    la.last_date as last_application_date
  FROM user_rewards ur
  CROSS JOIN user_tenka ut
  CROSS JOIN last_app la;
END;
$$ LANGUAGE plpgsql;

-- 2. 申請可能かチェックする関数
CREATE OR REPLACE FUNCTION can_apply_for_rewards(
  user_id_param UUID,
  check_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE(
  can_apply BOOLEAN,
  reason TEXT,
  pending_amount DECIMAL
) AS $$
DECLARE
  day_of_week INTEGER;
  pending_rewards RECORD;
BEGIN
  -- 曜日チェック（0=日曜, 6=土曜）
  day_of_week := EXTRACT(DOW FROM check_date);
  
  -- 土日は申請不可
  IF day_of_week = 0 OR day_of_week = 6 THEN
    RETURN QUERY SELECT false, '土日は申請できません', 0::DECIMAL;
    RETURN;
  END IF;
  
  -- 未申請報酬を取得
  SELECT * INTO pending_rewards 
  FROM get_user_pending_rewards(user_id_param);
  
  -- 50ドル未満は申請不可
  IF pending_rewards.total_amount < 50 THEN
    RETURN QUERY SELECT 
      false, 
      '申請には50ドル以上の未申請報酬が必要です', 
      pending_rewards.total_amount;
    RETURN;
  END IF;
  
  -- 申請可能
  RETURN QUERY SELECT 
    true, 
    '申請可能です', 
    pending_rewards.total_amount;
END;
$$ LANGUAGE plpgsql;

-- 3. テスト用のサンプルデータ作成
INSERT INTO daily_rewards (user_nft_id, reward_date, daily_rate, reward_amount, week_start_date, is_claimed)
SELECT 
  un.id,
  CURRENT_DATE - 1,
  0.01,
  un.current_investment * 0.01,
  CURRENT_DATE - EXTRACT(DOW FROM CURRENT_DATE)::INTEGER + 1,
  false
FROM user_nfts un
WHERE un.is_active = true
LIMIT 10;

-- テスト実行
SELECT 'Reward calculation functions created successfully' as status;
