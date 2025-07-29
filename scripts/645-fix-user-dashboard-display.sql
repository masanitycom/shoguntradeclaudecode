-- ユーザーダッシュボード表示の修正

-- 1. ユーザー報酬集計関数の修正
CREATE OR REPLACE FUNCTION get_user_reward_summary(p_user_id UUID)
RETURNS TABLE(
    total_investment DECIMAL(10,2),
    total_rewards DECIMAL(10,2),
    pending_rewards DECIMAL(10,2),
    reward_percentage DECIMAL(5,2),
    active_nfts INTEGER
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(SUM(un.purchase_price), 0) as total_investment,
        COALESCE(SUM(dr.reward_amount), 0) as total_rewards,
        COALESCE(SUM(
            CASE WHEN ra.status = 'pending' THEN ra.amount ELSE 0 END
        ), 0) as pending_rewards,
        CASE 
            WHEN COALESCE(SUM(un.purchase_price), 0) > 0 
            THEN (COALESCE(SUM(dr.reward_amount), 0) / SUM(un.purchase_price) * 100)
            ELSE 0 
        END as reward_percentage,
        COUNT(DISTINCT un.id)::INTEGER as active_nfts
    FROM user_nfts un
    LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id
    LEFT JOIN reward_applications ra ON un.user_id = ra.user_id
    WHERE un.user_id = p_user_id 
      AND un.is_active = true;
END;
$$;

-- 2. 管理画面用ユーザー一覧関数の修正
CREATE OR REPLACE FUNCTION get_admin_users_with_rewards()
RETURNS TABLE(
    user_id UUID,
    user_name TEXT,
    email TEXT,
    total_investment DECIMAL(10,2),
    total_rewards DECIMAL(10,2),
    reward_percentage DECIMAL(5,2),
    active_nfts INTEGER,
    last_reward_date DATE
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id as user_id,
        u.name::TEXT as user_name,
        u.email::TEXT,
        COALESCE(SUM(un.purchase_price), 0) as total_investment,
        COALESCE(SUM(dr.reward_amount), 0) as total_rewards,
        CASE 
            WHEN COALESCE(SUM(un.purchase_price), 0) > 0 
            THEN (COALESCE(SUM(dr.reward_amount), 0) / SUM(un.purchase_price) * 100)
            ELSE 0 
        END as reward_percentage,
        COUNT(DISTINCT un.id)::INTEGER as active_nfts,
        MAX(dr.reward_date) as last_reward_date
    FROM users u
    LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
    LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id
    WHERE u.is_admin = false
    GROUP BY u.id, u.name, u.email
    ORDER BY total_rewards DESC;
END;
$$;

-- 3. ダッシュボード用の統計関数
CREATE OR REPLACE FUNCTION get_system_statistics()
RETURNS TABLE(
    total_users INTEGER,
    active_nfts INTEGER,
    total_investment DECIMAL(10,2),
    total_rewards DECIMAL(10,2),
    pending_applications INTEGER
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM users WHERE is_admin = false) as total_users,
        (SELECT COUNT(*)::INTEGER FROM user_nfts WHERE is_active = true) as active_nfts,
        (SELECT COALESCE(SUM(purchase_price), 0) FROM user_nfts WHERE is_active = true) as total_investment,
        (SELECT COALESCE(SUM(reward_amount), 0) FROM daily_rewards) as total_rewards,
        (SELECT COUNT(*)::INTEGER FROM reward_applications WHERE status = 'pending') as pending_applications;
END;
$$;
