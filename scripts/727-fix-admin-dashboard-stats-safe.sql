-- 管理画面統計関数の安全な修正

-- 既存の関数を削除して再作成
DROP FUNCTION IF EXISTS get_admin_dashboard_stats();

-- 安全な管理画面統計関数を作成
CREATE OR REPLACE FUNCTION get_admin_dashboard_stats()
RETURNS TABLE(
    total_users INTEGER,
    active_nfts INTEGER,
    pending_applications INTEGER,
    total_rewards DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM users) as total_users,
        (SELECT COUNT(*)::INTEGER FROM user_nfts WHERE is_active = true) as active_nfts,
        (SELECT COUNT(*)::INTEGER FROM nft_purchase_applications WHERE status = 'pending') as pending_applications,
        0::DECIMAL as total_rewards; -- 報酬データクリア後は0
END;
$$ LANGUAGE plpgsql;

-- ユーザーダッシュボード統計関数も安全に修正
DROP FUNCTION IF EXISTS get_user_dashboard_stats(UUID);

CREATE OR REPLACE FUNCTION get_user_dashboard_stats(p_user_id UUID)
RETURNS TABLE(
    total_investment DECIMAL,
    total_earned DECIMAL,
    pending_rewards DECIMAL,
    current_rank TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (
            SELECT COALESCE(SUM(n.price), 0)::DECIMAL
            FROM user_nfts un
            JOIN nfts n ON un.nft_id = n.id
            WHERE un.user_id = p_user_id AND un.is_active = true
        ) as total_investment,
        0::DECIMAL as total_earned, -- クリア後は0
        0::DECIMAL as pending_rewards, -- クリア後は0
        (
            CASE 
                WHEN (
                    SELECT COALESCE(SUM(n.price), 0)
                    FROM user_nfts un
                    JOIN nfts n ON un.nft_id = n.id
                    WHERE un.user_id = p_user_id AND un.is_active = true
                ) >= 1000 THEN '足軽'
                ELSE 'なし'
            END
        ) as current_rank;
END;
$$ LANGUAGE plpgsql;

SELECT 'Safe admin dashboard stats functions created' as status;
