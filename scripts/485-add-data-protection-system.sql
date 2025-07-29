-- データ保護システムの追加

-- 1. 週利設定のバックアップテーブルを作成
CREATE TABLE IF NOT EXISTS group_weekly_rates_backup (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    original_id UUID,
    group_id UUID,
    week_start_date DATE,
    weekly_rate NUMERIC,
    monday_rate NUMERIC,
    tuesday_rate NUMERIC,
    wednesday_rate NUMERIC,
    thursday_rate NUMERIC,
    friday_rate NUMERIC,
    backup_created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    backup_reason TEXT,
    created_by UUID
);

-- 2. 自動バックアップトリガーを作成
CREATE OR REPLACE FUNCTION backup_weekly_rates()
RETURNS TRIGGER AS $$
BEGIN
    -- 削除の場合はバックアップを作成
    IF TG_OP = 'DELETE' THEN
        INSERT INTO group_weekly_rates_backup (
            original_id,
            group_id,
            week_start_date,
            weekly_rate,
            monday_rate,
            tuesday_rate,
            wednesday_rate,
            thursday_rate,
            friday_rate,
            backup_reason
        ) VALUES (
            OLD.id,
            OLD.group_id,
            OLD.week_start_date,
            OLD.weekly_rate,
            OLD.monday_rate,
            OLD.tuesday_rate,
            OLD.wednesday_rate,
            OLD.thursday_rate,
            OLD.friday_rate,
            'AUTO_BACKUP_ON_DELETE'
        );
        RETURN OLD;
    END IF;
    
    -- 更新の場合も古い値をバックアップ
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO group_weekly_rates_backup (
            original_id,
            group_id,
            week_start_date,
            weekly_rate,
            monday_rate,
            tuesday_rate,
            wednesday_rate,
            thursday_rate,
            friday_rate,
            backup_reason
        ) VALUES (
            OLD.id,
            OLD.group_id,
            OLD.week_start_date,
            OLD.weekly_rate,
            OLD.monday_rate,
            OLD.tuesday_rate,
            OLD.wednesday_rate,
            OLD.thursday_rate,
            OLD.friday_rate,
            'AUTO_BACKUP_ON_UPDATE'
        );
        RETURN NEW;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 3. トリガーを設定
DROP TRIGGER IF EXISTS weekly_rates_backup_trigger ON group_weekly_rates;
CREATE TRIGGER weekly_rates_backup_trigger
    BEFORE DELETE OR UPDATE ON group_weekly_rates
    FOR EACH ROW EXECUTE FUNCTION backup_weekly_rates();

-- 4. 手動バックアップ関数
CREATE OR REPLACE FUNCTION create_manual_backup(backup_reason TEXT DEFAULT 'MANUAL_BACKUP')
RETURNS INTEGER AS $$
DECLARE
    backup_count INTEGER := 0;
BEGIN
    INSERT INTO group_weekly_rates_backup (
        original_id,
        group_id,
        week_start_date,
        weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        backup_reason
    )
    SELECT 
        id,
        group_id,
        week_start_date,
        weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        backup_reason
    FROM group_weekly_rates;
    
    GET DIAGNOSTICS backup_count = ROW_COUNT;
    RETURN backup_count;
END;
$$ LANGUAGE plpgsql;

-- 5. バックアップからの復元関数
CREATE OR REPLACE FUNCTION restore_from_backup(
    target_backup_date TIMESTAMP WITH TIME ZONE
)
RETURNS INTEGER AS $$
DECLARE
    restore_count INTEGER := 0;
BEGIN
    -- 現在のデータを削除
    DELETE FROM group_weekly_rates;
    
    -- バックアップから復元
    INSERT INTO group_weekly_rates (
        group_id,
        week_start_date,
        weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        created_at,
        updated_at
    )
    SELECT DISTINCT ON (group_id, week_start_date)
        group_id,
        week_start_date,
        weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        backup_created_at,
        NOW()
    FROM group_weekly_rates_backup
    WHERE backup_created_at <= target_backup_date
    ORDER BY group_id, week_start_date, backup_created_at DESC;
    
    GET DIAGNOSTICS restore_count = ROW_COUNT;
    RETURN restore_count;
END;
$$ LANGUAGE plpgsql;

-- 6. 現在の設定を手動バックアップ
SELECT create_manual_backup('INITIAL_BACKUP_AFTER_RESET') as backup_count;

-- 7. バックアップ状況確認
SELECT 
    '📋 バックアップシステム確認' as section,
    COUNT(*) as total_backups,
    COUNT(DISTINCT backup_reason) as backup_types,
    MIN(backup_created_at) as earliest_backup,
    MAX(backup_created_at) as latest_backup
FROM group_weekly_rates_backup;
