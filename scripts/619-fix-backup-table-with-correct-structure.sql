-- 正しい構造でバックアップテーブルを修正

-- 1. 既存のバックアップテーブルを削除して再作成
DROP TABLE IF EXISTS group_weekly_rates_backup CASCADE;

-- 2. 正しい構造でバックアップテーブルを作成
CREATE TABLE group_weekly_rates_backup (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    original_id UUID,
    group_id UUID,
    week_start_date DATE NOT NULL,
    week_end_date DATE NOT NULL,
    weekly_rate NUMERIC(5,4) NOT NULL,
    monday_rate NUMERIC(5,4) NOT NULL,
    tuesday_rate NUMERIC(5,4) NOT NULL,
    wednesday_rate NUMERIC(5,4) NOT NULL,
    thursday_rate NUMERIC(5,4) NOT NULL,
    friday_rate NUMERIC(5,4) NOT NULL,
    distribution_method TEXT DEFAULT 'random',
    backup_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    backup_reason TEXT DEFAULT 'System backup',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. インデックス作成
CREATE INDEX idx_backup_week_start_date ON group_weekly_rates_backup(week_start_date);
CREATE INDEX idx_backup_timestamp ON group_weekly_rates_backup(backup_timestamp);

-- 4. 修正されたlist_weekly_rates_backups関数
DROP FUNCTION IF EXISTS list_weekly_rates_backups();

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
        COALESCE(gwrb.backup_reason, 'No reason specified') as backup_reason,
        COUNT(*) as group_count
    FROM group_weekly_rates_backup gwrb
    GROUP BY gwrb.week_start_date, gwrb.backup_timestamp, gwrb.backup_reason
    ORDER BY gwrb.backup_timestamp DESC;
END;
$$ LANGUAGE plpgsql;

-- 5. get_backup_list関数（管理UI用）
DROP FUNCTION IF EXISTS get_backup_list();

CREATE OR REPLACE FUNCTION get_backup_list()
RETURNS TABLE(
    week_start_date DATE,
    backup_timestamp TIMESTAMP WITH TIME ZONE,
    backup_reason TEXT,
    group_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM list_weekly_rates_backups();
END;
$$ LANGUAGE plpgsql;

-- 6. テスト実行
SELECT 'Testing backup functions...' as status;

-- 空のテーブルでもエラーが出ないかテスト
SELECT * FROM list_weekly_rates_backups();

SELECT 'Backup table structure fixed successfully!' as status;
