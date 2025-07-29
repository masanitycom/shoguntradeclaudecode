-- バックアップシステムの構築

-- 1. バックアップテーブルの作成
DROP TABLE IF EXISTS group_weekly_rates_backup CASCADE;

CREATE TABLE group_weekly_rates_backup (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    original_id UUID NOT NULL,
    week_start_date DATE NOT NULL,
    week_end_date DATE,
    weekly_rate NUMERIC(10,6) NOT NULL,
    monday_rate NUMERIC(10,6),
    tuesday_rate NUMERIC(10,6),
    wednesday_rate NUMERIC(10,6),
    thursday_rate NUMERIC(10,6),
    friday_rate NUMERIC(10,6),
    group_id UUID NOT NULL,
    group_name TEXT,
    distribution_method TEXT,
    backup_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    backup_reason TEXT DEFAULT 'System backup',
    backup_type TEXT DEFAULT 'manual',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- インデックス作成
CREATE INDEX idx_backup_week_start ON group_weekly_rates_backup(week_start_date);
CREATE INDEX idx_backup_timestamp ON group_weekly_rates_backup(backup_timestamp);
CREATE INDEX idx_backup_group ON group_weekly_rates_backup(group_id);

-- 2. 自動バックアップ関数
CREATE OR REPLACE FUNCTION create_automatic_backup(
    p_reason TEXT DEFAULT 'Automatic backup'
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    backup_count INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    backup_count INTEGER := 0;
BEGIN
    -- 現在の全設定をバックアップ
    INSERT INTO group_weekly_rates_backup (
        original_id,
        week_start_date,
        week_end_date,
        weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        group_id,
        group_name,
        distribution_method,
        backup_reason,
        backup_type
    )
    SELECT 
        gwr.id,
        gwr.week_start_date,
        gwr.week_end_date,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        gwr.group_id,
        gwr.group_name,
        gwr.distribution_method,
        p_reason,
        'automatic'
    FROM group_weekly_rates gwr;
    
    GET DIAGNOSTICS backup_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true,
        format('✅ %s件の週利設定をバックアップしました', backup_count),
        backup_count;
END;
$$;

-- 3. 手動バックアップ関数
CREATE OR REPLACE FUNCTION admin_create_backup(
    p_week_start_date DATE DEFAULT NULL,
    p_reason TEXT DEFAULT 'Manual backup from admin UI'
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    backup_count INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    backup_count INTEGER := 0;
BEGIN
    IF p_week_start_date IS NULL THEN
        -- 全設定をバックアップ
        INSERT INTO group_weekly_rates_backup (
            original_id,
            week_start_date,
            week_end_date,
            weekly_rate,
            monday_rate,
            tuesday_rate,
            wednesday_rate,
            thursday_rate,
            friday_rate,
            group_id,
            group_name,
            distribution_method,
            backup_reason,
            backup_type
        )
        SELECT 
            gwr.id,
            gwr.week_start_date,
            gwr.week_end_date,
            gwr.weekly_rate,
            gwr.monday_rate,
            gwr.tuesday_rate,
            gwr.wednesday_rate,
            gwr.thursday_rate,
            gwr.friday_rate,
            gwr.group_id,
            gwr.group_name,
            gwr.distribution_method,
            p_reason,
            'manual'
        FROM group_weekly_rates gwr;
    ELSE
        -- 指定週のみバックアップ
        INSERT INTO group_weekly_rates_backup (
            original_id,
            week_start_date,
            week_end_date,
            weekly_rate,
            monday_rate,
            tuesday_rate,
            wednesday_rate,
            thursday_rate,
            friday_rate,
            group_id,
            group_name,
            distribution_method,
            backup_reason,
            backup_type
        )
        SELECT 
            gwr.id,
            gwr.week_start_date,
            gwr.week_end_date,
            gwr.weekly_rate,
            gwr.monday_rate,
            gwr.tuesday_rate,
            gwr.wednesday_rate,
            gwr.thursday_rate,
            gwr.friday_rate,
            gwr.group_id,
            gwr.group_name,
            gwr.distribution_method,
            p_reason,
            'manual'
        FROM group_weekly_rates gwr
        WHERE gwr.week_start_date = p_week_start_date;
    END IF;
    
    GET DIAGNOSTICS backup_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true,
        format('✅ %s件の週利設定をバックアップしました', backup_count),
        backup_count;
END;
$$;

-- 4. バックアップ一覧取得関数
CREATE OR REPLACE FUNCTION get_backup_list()
RETURNS TABLE(
    week_start_date DATE,
    backup_timestamp TIMESTAMP WITH TIME ZONE,
    backup_reason TEXT,
    group_count BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwrb.week_start_date,
        gwrb.backup_timestamp,
        COALESCE(gwrb.backup_reason, 'Unknown') as backup_reason,
        COUNT(*) as group_count
    FROM group_weekly_rates_backup gwrb
    GROUP BY gwrb.week_start_date, gwrb.backup_timestamp, gwrb.backup_reason
    ORDER BY gwrb.backup_timestamp DESC;
END;
$$;

-- 5. 復元関数
CREATE OR REPLACE FUNCTION admin_restore_from_backup(
    p_week_start_date DATE,
    p_backup_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    restored_count INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    restored_count INTEGER := 0;
    backup_timestamp TIMESTAMP WITH TIME ZONE;
BEGIN
    -- バックアップタイムスタンプが指定されていない場合は最新を使用
    IF p_backup_timestamp IS NULL THEN
        SELECT MAX(gwrb.backup_timestamp) INTO backup_timestamp
        FROM group_weekly_rates_backup gwrb
        WHERE gwrb.week_start_date = p_week_start_date;
    ELSE
        backup_timestamp := p_backup_timestamp;
    END IF;
    
    IF backup_timestamp IS NULL THEN
        RETURN QUERY SELECT 
            false,
            format('❌ %sのバックアップが見つかりません', p_week_start_date::TEXT),
            0;
        RETURN;
    END IF;
    
    -- 既存データを削除
    DELETE FROM group_weekly_rates WHERE week_start_date = p_week_start_date;
    
    -- バックアップから復元
    INSERT INTO group_weekly_rates (
        id,
        week_start_date,
        week_end_date,
        weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        group_id,
        group_name,
        distribution_method,
        created_at,
        updated_at
    )
    SELECT 
        gen_random_uuid(),
        gwrb.week_start_date,
        gwrb.week_end_date,
        gwrb.weekly_rate,
        gwrb.monday_rate,
        gwrb.tuesday_rate,
        gwrb.wednesday_rate,
        gwrb.thursday_rate,
        gwrb.friday_rate,
        gwrb.group_id,
        gwrb.group_name,
        gwrb.distribution_method,
        NOW(),
        NOW()
    FROM group_weekly_rates_backup gwrb
    WHERE gwrb.week_start_date = p_week_start_date 
    AND gwrb.backup_timestamp = admin_restore_from_backup.backup_timestamp;
    
    GET DIAGNOSTICS restored_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true,
        format('✅ %sの週利設定を%s件復元しました', p_week_start_date::TEXT, restored_count),
        restored_count;
END;
$$;

-- 6. 現在の設定を初回バックアップとして保存
SELECT create_automatic_backup('Initial backup after restoration') as initial_backup_result;

-- 権限設定
GRANT EXECUTE ON FUNCTION create_automatic_backup(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_create_backup(DATE, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_backup_list() TO authenticated;
GRANT EXECUTE ON FUNCTION admin_restore_from_backup(DATE, TIMESTAMP WITH TIME ZONE) TO authenticated;
