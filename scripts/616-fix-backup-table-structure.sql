-- バックアップテーブル構造の修正

-- 1. 現在のバックアップテーブル構造確認
SELECT 'Checking current backup table structure...' as status;

SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates_backup' 
ORDER BY ordinal_position;

-- 2. バックアップテーブルが存在しない場合は作成
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

-- 3. backup_timestampカラムが存在しない場合は追加
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'group_weekly_rates_backup' 
        AND column_name = 'backup_timestamp'
    ) THEN
        ALTER TABLE group_weekly_rates_backup 
        ADD COLUMN backup_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- 4. backup_reasonカラムが存在しない場合は追加
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'group_weekly_rates_backup' 
        AND column_name = 'backup_reason'
    ) THEN
        ALTER TABLE group_weekly_rates_backup 
        ADD COLUMN backup_reason TEXT;
    END IF;
END $$;

-- 5. 修正後のテーブル構造確認
SELECT 'Updated backup table structure:' as status;

SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates_backup' 
ORDER BY ordinal_position;

-- 6. list_weekly_rates_backups関数を修正
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
        COALESCE(gwrb.backup_timestamp, gwrb.created_at) as backup_timestamp,
        COALESCE(gwrb.backup_reason, 'No reason specified') as backup_reason,
        COUNT(*) as group_count
    FROM group_weekly_rates_backup gwrb
    GROUP BY gwrb.week_start_date, 
             COALESCE(gwrb.backup_timestamp, gwrb.created_at), 
             COALESCE(gwrb.backup_reason, 'No reason specified')
    ORDER BY COALESCE(gwrb.backup_timestamp, gwrb.created_at) DESC;
END;
$$ LANGUAGE plpgsql;

-- 7. get_backup_list関数を作成（管理UI用）
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

-- 8. テスト実行
SELECT 'Testing fixed backup functions...' as status;

SELECT * FROM list_weekly_rates_backups() LIMIT 5;

SELECT 'Backup table structure fixed successfully!' as status;
