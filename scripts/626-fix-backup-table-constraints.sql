-- バックアップテーブルの制約修正

-- 1. 現在のバックアップテーブル構造確認
SELECT 
    '📋 現在のバックアップテーブル構造' as section,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates_backup' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. week_end_dateの制約を緩和
ALTER TABLE group_weekly_rates_backup 
ALTER COLUMN week_end_date DROP NOT NULL;

-- 3. バックアップ作成関数を修正（week_end_dateを正しく計算）
CREATE OR REPLACE FUNCTION admin_create_backup(
    p_week_start_date DATE,
    p_reason TEXT DEFAULT 'Manual backup'
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    backup_count INTEGER
) AS $$
DECLARE
    backup_count INTEGER := 0;
BEGIN
    -- 指定週のデータをバックアップ（week_end_dateを計算）
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
        COALESCE(gwr.week_end_date, gwr.week_start_date + INTERVAL '4 days') as week_end_date,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        COALESCE(gwr.distribution_method, 'random'),
        p_reason
    FROM group_weekly_rates gwr
    WHERE gwr.week_start_date = p_week_start_date;
    
    GET DIAGNOSTICS backup_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true,
        format('%sのデータを%s件バックアップしました', p_week_start_date::TEXT, backup_count),
        backup_count;
END;
$$ LANGUAGE plpgsql;

-- 4. 削除関数を修正（エラーハンドリング強化）
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
    backup_result RECORD;
BEGIN
    -- まずバックアップを作成
    SELECT * INTO backup_result 
    FROM admin_create_backup(p_week_start_date, 'Before deletion: ' || p_reason) 
    LIMIT 1;
    
    IF NOT backup_result.success THEN
        RETURN QUERY SELECT 
            false,
            'バックアップ作成に失敗: ' || backup_result.message,
            0;
        RETURN;
    END IF;
    
    -- データを削除
    DELETE FROM group_weekly_rates 
    WHERE week_start_date = p_week_start_date;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true,
        format('%sの週利設定を%s件削除しました（バックアップ済み）', p_week_start_date::TEXT, deleted_count),
        deleted_count;
        
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 
        false,
        '削除エラー: ' || SQLERRM,
        0;
END;
$$ LANGUAGE plpgsql;

-- 5. 復元関数を修正
CREATE OR REPLACE FUNCTION admin_restore_from_backup(
    p_week_start_date DATE,
    p_backup_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NULL
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    restored_count INTEGER
) AS $$
DECLARE
    restored_count INTEGER := 0;
    backup_timestamp TIMESTAMP WITH TIME ZONE;
BEGIN
    -- バックアップタイムスタンプが指定されていない場合は最新を使用
    IF p_backup_timestamp IS NULL THEN
        SELECT MAX(backup_timestamp) INTO backup_timestamp
        FROM group_weekly_rates_backup
        WHERE week_start_date = p_week_start_date;
    ELSE
        backup_timestamp := p_backup_timestamp;
    END IF;
    
    IF backup_timestamp IS NULL THEN
        RETURN QUERY SELECT 
            false,
            format('%sのバックアップが見つかりません', p_week_start_date::TEXT),
            0;
        RETURN;
    END IF;
    
    -- 既存データを削除
    DELETE FROM group_weekly_rates WHERE week_start_date = p_week_start_date;
    
    -- バックアップから復元（week_end_dateを計算）
    INSERT INTO group_weekly_rates (
        group_id,
        week_start_date,
        week_end_date,
        weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        distribution_method
    )
    SELECT 
        group_id,
        week_start_date,
        COALESCE(week_end_date, week_start_date + INTERVAL '4 days') as week_end_date,
        weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        COALESCE(distribution_method, 'random')
    FROM group_weekly_rates_backup
    WHERE week_start_date = p_week_start_date 
    AND backup_timestamp = admin_restore_from_backup.backup_timestamp;
    
    GET DIAGNOSTICS restored_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true,
        format('%sの週利設定を%s件復元しました', p_week_start_date::TEXT, restored_count),
        restored_count;
        
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 
        false,
        '復元エラー: ' || SQLERRM,
        0;
END;
$$ LANGUAGE plpgsql;

SELECT 'Backup table constraints fixed successfully!' as status;
