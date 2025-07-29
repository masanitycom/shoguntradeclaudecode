-- 週利設定のバックアップ・削除システム

-- 1. バックアップテーブル作成
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

-- 2. バックアップ作成関数
CREATE OR REPLACE FUNCTION create_weekly_rates_backup(
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
    -- 指定週のデータをバックアップ
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

-- 3. 週利設定削除関数（バックアップ付き）
CREATE OR REPLACE FUNCTION delete_weekly_rates_with_backup(
    p_week_start_date DATE,
    p_reason TEXT DEFAULT 'Manual deletion'
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    deleted_count INTEGER
) AS $$
DECLARE
    deleted_count INTEGER := 0;
BEGIN
    -- まずバックアップを作成
    PERFORM create_weekly_rates_backup(p_week_start_date, 'Before deletion: ' || p_reason);
    
    -- データを削除
    DELETE FROM group_weekly_rates 
    WHERE week_start_date = p_week_start_date;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true,
        format('%sの週利設定を%s件削除しました（バックアップ済み）', p_week_start_date::TEXT, deleted_count),
        deleted_count;
END;
$$ LANGUAGE plpgsql;

-- 4. バックアップからの復元関数
CREATE OR REPLACE FUNCTION restore_weekly_rates_from_backup(
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
    
    -- バックアップから復元
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
        week_end_date,
        weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        distribution_method
    FROM group_weekly_rates_backup
    WHERE week_start_date = p_week_start_date 
    AND backup_timestamp = restore_weekly_rates_from_backup.backup_timestamp;
    
    GET DIAGNOSTICS restored_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true,
        format('%sの週利設定を%s件復元しました', p_week_start_date::TEXT, restored_count),
        restored_count;
END;
$$ LANGUAGE plpgsql;

-- 5. バックアップ一覧表示関数
CREATE OR REPLACE FUNCTION list_weekly_rates_backups()
RETURNS TABLE(
    week_start_date DATE,
    backup_timestamp TIMESTAMP WITH TIME ZONE,
    backup_reason TEXT,
    group_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwrb.week_start_date,
        gwrb.backup_timestamp,
        gwrb.backup_reason,
        COUNT(*) as group_count
    FROM group_weekly_rates_backup gwrb
    GROUP BY gwrb.week_start_date, gwrb.backup_timestamp, gwrb.backup_reason
    ORDER BY gwrb.backup_timestamp DESC;
END;
$$ LANGUAGE plpgsql;

-- 6. 特定週のバックアップ詳細表示
CREATE OR REPLACE FUNCTION show_backup_details(
    p_week_start_date DATE
) RETURNS TABLE(
    backup_timestamp TIMESTAMP WITH TIME ZONE,
    backup_reason TEXT,
    group_name TEXT,
    weekly_rate_percent NUMERIC,
    monday_percent NUMERIC,
    tuesday_percent NUMERIC,
    wednesday_percent NUMERIC,
    thursday_percent NUMERIC,
    friday_percent NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwrb.backup_timestamp,
        gwrb.backup_reason,
        drg.group_name::TEXT,
        ROUND(gwrb.weekly_rate * 100, 2),
        ROUND(gwrb.monday_rate * 100, 2),
        ROUND(gwrb.tuesday_rate * 100, 2),
        ROUND(gwrb.wednesday_rate * 100, 2),
        ROUND(gwrb.thursday_rate * 100, 2),
        ROUND(gwrb.friday_rate * 100, 2)
    FROM group_weekly_rates_backup gwrb
    JOIN daily_rate_groups drg ON gwrb.group_id = drg.id
    WHERE gwrb.week_start_date = p_week_start_date
    ORDER BY gwrb.backup_timestamp DESC, drg.daily_rate_limit;
END;
$$ LANGUAGE plpgsql;

-- 完了メッセージ
SELECT 'Created backup and delete system for weekly rates' as status;
