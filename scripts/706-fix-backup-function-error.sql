-- バックアップ関数のエラー修正

-- 1. 問題のある関数を削除
DROP FUNCTION IF EXISTS get_backup_list();

-- 2. 正しい戻り値型で関数を再作成
CREATE OR REPLACE FUNCTION get_backup_list()
RETURNS TABLE(
    week_start_date DATE,
    backup_timestamp TEXT,
    backup_reason TEXT,
    group_count BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwrb.week_start_date,
        gwrb.backup_timestamp::TEXT as backup_timestamp,
        COALESCE(gwrb.backup_reason, 'Unknown') as backup_reason,
        COUNT(*) as group_count
    FROM group_weekly_rates_backup gwrb
    GROUP BY gwrb.week_start_date, gwrb.backup_timestamp, gwrb.backup_reason
    ORDER BY gwrb.backup_timestamp DESC;
END;
$$;

-- 3. 権限設定
GRANT EXECUTE ON FUNCTION get_backup_list() TO authenticated;
