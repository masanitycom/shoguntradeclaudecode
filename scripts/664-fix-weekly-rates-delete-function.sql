-- 週利設定削除機能の修正

-- 1. 既存の削除関数を確認・削除
DROP FUNCTION IF EXISTS admin_delete_weekly_rates(DATE, TEXT);
DROP FUNCTION IF EXISTS delete_weekly_rates_with_backup(DATE, TEXT);

-- 2. バックアップ付き削除関数を作成
CREATE OR REPLACE FUNCTION admin_delete_weekly_rates(
    p_week_start_date DATE,
    p_reason TEXT DEFAULT 'Manual deletion'
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    deleted_count INTEGER
) AS $$
DECLARE
    deleted_count INTEGER := 0;
    backup_count INTEGER := 0;
BEGIN
    -- まずバックアップを作成
    INSERT INTO group_weekly_rates_backup (
        original_id,
        group_id,
        week_start_date,
        week_end_date,
        weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        distribution_method,
        backup_reason
    )
    SELECT 
        gwr.id,
        gwr.group_id,
        gwr.week_start_date,
        gwr.week_end_date,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        gwr.distribution_method,
        'Before deletion: ' || p_reason
    FROM group_weekly_rates gwr
    WHERE gwr.week_start_date = p_week_start_date;
    
    GET DIAGNOSTICS backup_count = ROW_COUNT;
    
    -- 関連する日利報酬データも削除（必要に応じて）
    DELETE FROM daily_rewards 
    WHERE reward_date >= p_week_start_date 
    AND reward_date < p_week_start_date + INTERVAL '7 days';
    
    -- 週利設定を削除
    DELETE FROM group_weekly_rates 
    WHERE week_start_date = p_week_start_date;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    IF deleted_count > 0 THEN
        RETURN QUERY SELECT 
            true,
            format('%sの週利設定を%s件削除しました（%s件バックアップ済み）', 
                   p_week_start_date::TEXT, deleted_count, backup_count),
            deleted_count;
    ELSE
        RETURN QUERY SELECT 
            false,
            format('%sの週利設定が見つかりませんでした', p_week_start_date::TEXT),
            0;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT 
            false,
            format('削除エラー: %s', SQLERRM),
            0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. バックアップテーブルが存在しない場合は作成
CREATE TABLE IF NOT EXISTS group_weekly_rates_backup (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    original_id UUID,
    group_id UUID,
    week_start_date DATE,
    week_end_date DATE,
    weekly_rate NUMERIC(5,4),
    monday_rate NUMERIC(5,4),
    tuesday_rate NUMERIC(5,4),
    wednesday_rate NUMERIC(5,4),
    thursday_rate NUMERIC(5,4),
    friday_rate NUMERIC(5,4),
    distribution_method TEXT DEFAULT 'random',
    backup_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    backup_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. 権限設定
GRANT EXECUTE ON FUNCTION admin_delete_weekly_rates(DATE, TEXT) TO authenticated;

-- 5. テスト用の削除関数（安全版）
CREATE OR REPLACE FUNCTION safe_delete_weekly_rates(
    p_week_start_date DATE
) RETURNS TABLE(
    can_delete BOOLEAN,
    message TEXT,
    affected_records INTEGER
) AS $$
DECLARE
    weekly_count INTEGER := 0;
    daily_count INTEGER := 0;
BEGIN
    -- 削除対象の週利設定数を確認
    SELECT COUNT(*) INTO weekly_count
    FROM group_weekly_rates
    WHERE week_start_date = p_week_start_date;
    
    -- 関連する日利報酬数を確認
    SELECT COUNT(*) INTO daily_count
    FROM daily_rewards
    WHERE reward_date >= p_week_start_date 
    AND reward_date < p_week_start_date + INTERVAL '7 days';
    
    RETURN QUERY SELECT 
        weekly_count > 0,
        format('週利設定: %s件, 関連日利報酬: %s件', weekly_count, daily_count),
        weekly_count + daily_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 完了メッセージ
SELECT 'Fixed weekly rates delete function' as status;
