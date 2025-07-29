-- バックアップ関数の曖昧性エラーを修正

-- 既存の重複する関数を削除
DROP FUNCTION IF EXISTS admin_create_backup(date);
DROP FUNCTION IF EXISTS admin_create_backup(date, text);

-- 統一されたバックアップ作成関数を作成
CREATE OR REPLACE FUNCTION admin_create_backup(
    p_week_start_date DATE,
    p_reason TEXT DEFAULT 'Manual backup'
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    backup_count INTEGER;
BEGIN
    -- 既存のバックアップをチェック
    SELECT COUNT(*) INTO backup_count
    FROM group_weekly_rates_backup
    WHERE week_start_date = p_week_start_date;
    
    -- バックアップ作成
    INSERT INTO group_weekly_rates_backup (
        week_start_date,
        group_name,
        weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        distribution_method,
        backup_timestamp,
        backup_reason
    )
    SELECT 
        gwr.week_start_date,
        gwr.group_name,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        gwr.distribution_method,
        NOW(),
        p_reason
    FROM group_weekly_rates gwr
    WHERE gwr.week_start_date = p_week_start_date;
    
    RETURN QUERY SELECT 
        true,
        format('バックアップ作成完了: %s週分', p_week_start_date);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 権限設定
GRANT EXECUTE ON FUNCTION admin_create_backup(DATE, TEXT) TO authenticated;

-- テスト実行
SELECT 'Fixed admin_create_backup function ambiguity' as status;
