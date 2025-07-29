-- システム状況取得関数の修正
-- deleted_atカラムエラーを修正

-- 既存の関数を削除
DROP FUNCTION IF EXISTS get_system_status();

-- システム状況取得関数を再作成
CREATE OR REPLACE FUNCTION get_system_status()
RETURNS TABLE (
    total_users bigint,
    active_nfts bigint,
    pending_rewards numeric,
    last_calculation text,
    current_week_rates bigint,
    total_backups bigint
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        -- 総ユーザー数（削除されていないユーザー）
        (SELECT COUNT(*) FROM users WHERE email IS NOT NULL)::bigint as total_users,
        
        -- アクティブNFT数（is_active = trueのuser_nfts）
        (SELECT COUNT(*) FROM user_nfts WHERE is_active = true)::bigint as active_nfts,
        
        -- 保留中報酬（未申請の日利報酬合計）
        COALESCE((
            SELECT SUM(reward_amount) 
            FROM daily_rewards dr
            WHERE NOT EXISTS (
                SELECT 1 FROM reward_applications ra 
                WHERE ra.user_id = dr.user_id 
                AND ra.reward_date = dr.reward_date
                AND ra.status = 'approved'
            )
        ), 0)::numeric as pending_rewards,
        
        -- 最終計算日時
        COALESCE((
            SELECT TO_CHAR(MAX(created_at), 'YYYY-MM-DD HH24:MI:SS') 
            FROM daily_rewards
        ), '未実行') as last_calculation,
        
        -- 設定済み週数
        (SELECT COUNT(DISTINCT week_start_date) FROM group_weekly_rates)::bigint as current_week_rates,
        
        -- バックアップ数
        COALESCE((
            SELECT COUNT(DISTINCT week_start_date) 
            FROM group_weekly_rates_backup
        ), 0)::bigint as total_backups;
END;
$$;

-- 関数の実行権限を設定
GRANT EXECUTE ON FUNCTION get_system_status() TO authenticated;

-- テスト実行
SELECT * FROM get_system_status();
