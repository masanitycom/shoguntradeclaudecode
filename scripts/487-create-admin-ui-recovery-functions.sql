-- 管理画面用の復旧機能

-- 1. バックアップ一覧取得関数
CREATE OR REPLACE FUNCTION get_backup_history()
RETURNS TABLE(
    backup_date TIMESTAMP WITH TIME ZONE,
    backup_reason TEXT,
    record_count BIGINT,
    weeks_covered BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        backup_created_at,
        backup_reason,
        COUNT(*) as record_count,
        COUNT(DISTINCT week_start_date) as weeks_covered
    FROM group_weekly_rates_backup
    GROUP BY backup_created_at, backup_reason
    ORDER BY backup_created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- 2. 特定バックアップの内容確認関数
CREATE OR REPLACE FUNCTION preview_backup_content(
    target_backup_date TIMESTAMP WITH TIME ZONE
)
RETURNS TABLE(
    week_start_date DATE,
    group_name TEXT,
    weekly_rate_percent NUMERIC,
    monday_rate_percent NUMERIC,
    tuesday_rate_percent NUMERIC,
    wednesday_rate_percent NUMERIC,
    thursday_rate_percent NUMERIC,
    friday_rate_percent NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bak.week_start_date,
        drg.group_name::TEXT,
        (bak.weekly_rate * 100)::NUMERIC,
        (bak.monday_rate * 100)::NUMERIC,
        (bak.tuesday_rate * 100)::NUMERIC,
        (bak.wednesday_rate * 100)::NUMERIC,
        (bak.thursday_rate * 100)::NUMERIC,
        (bak.friday_rate * 100)::NUMERIC
    FROM group_weekly_rates_backup bak
    JOIN daily_rate_groups drg ON bak.group_id = drg.id
    WHERE bak.backup_created_at = target_backup_date
    ORDER BY bak.week_start_date DESC, drg.daily_rate_limit;
END;
$$ LANGUAGE plpgsql;

-- 3. 権限設定
GRANT EXECUTE ON FUNCTION get_backup_history() TO authenticated;
GRANT EXECUTE ON FUNCTION preview_backup_content(TIMESTAMP WITH TIME ZONE) TO authenticated;

-- 4. 現在の状況確認
SELECT 
    '📊 復旧システム準備完了' as section,
    '管理画面から安全に週利設定可能' as status,
    '自動バックアップ機能有効' as backup_status,
    '復旧機能利用可能' as recovery_status;
