-- 管理ダッシュボードの統計表示を修正

-- 1. 管理ダッシュボード用の統計関数を作成
CREATE OR REPLACE FUNCTION get_admin_dashboard_stats()
RETURNS TABLE(
    total_users INTEGER,
    active_nfts INTEGER,
    pending_applications INTEGER,
    total_rewards DECIMAL
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM users) as total_users,
        (SELECT COUNT(*)::INTEGER FROM user_nfts WHERE is_active = true) as active_nfts,
        (SELECT COUNT(*)::INTEGER FROM nft_purchase_applications WHERE status = 'pending') as pending_applications,
        (SELECT COALESCE(SUM(reward_amount), 0) FROM daily_rewards WHERE is_claimed = false) as total_rewards;
END;
$$;

-- 2. ユーザーダッシュボード用の統計関数を作成
CREATE OR REPLACE FUNCTION get_user_dashboard_stats(p_user_id UUID)
RETURNS TABLE(
    total_investment DECIMAL,
    total_earned DECIMAL,
    pending_rewards DECIMAL,
    current_rank TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    user_total_investment DECIMAL := 0;
    user_total_earned DECIMAL := 0;
    user_pending_rewards DECIMAL := 0;
    user_current_rank TEXT := 'なし';
BEGIN
    -- 総投資額（NFTの価格合計）
    SELECT COALESCE(SUM(n.price), 0) INTO user_total_investment
    FROM user_nfts un
    JOIN nfts n ON un.nft_id = n.id
    WHERE un.user_id = p_user_id AND un.is_active = true;
    
    -- 総獲得額
    SELECT COALESCE(SUM(un.total_earned), 0) INTO user_total_earned
    FROM user_nfts un
    WHERE un.user_id = p_user_id AND un.is_active = true;
    
    -- 保留中報酬
    SELECT COALESCE(SUM(dr.reward_amount), 0) INTO user_pending_rewards
    FROM daily_rewards dr
    WHERE dr.user_id = p_user_id AND dr.is_claimed = false;
    
    -- MLMランク（簡易版）
    IF user_total_investment >= 1000 THEN
        user_current_rank := '足軽';
    END IF;
    
    RETURN QUERY
    SELECT 
        user_total_investment,
        user_total_earned,
        user_pending_rewards,
        user_current_rank;
END;
$$;

-- 3. 権限設定
GRANT EXECUTE ON FUNCTION get_admin_dashboard_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_dashboard_stats(UUID) TO authenticated;

SELECT 'Dashboard stats functions created' as status;
