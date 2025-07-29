-- バックアップ履歴取得関数の修正（列参照の曖昧性エラー解消）

DROP FUNCTION IF EXISTS get_backup_history();

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
        bak.backup_created_at as backup_date,
        bak.backup_reason,
        COUNT(*) as record_count,
        COUNT(DISTINCT bak.week_start_date) as weeks_covered
    FROM group_weekly_rates_backup bak
    GROUP BY bak.backup_created_at, bak.backup_reason
    ORDER BY bak.backup_created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- 関数修正完了
SELECT '✅ get_backup_history関数を修正しました' as status;
