-- バックアップテーブル構造の修正

-- 1. 現在のバックアップテーブル構造を確認
DO $$
DECLARE
    col_exists BOOLEAN;
BEGIN
    -- daily_rate_group カラムが存在するかチェック
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'group_weekly_rates_backup' 
        AND column_name = 'daily_rate_group'
    ) INTO col_exists;
    
    IF NOT col_exists THEN
        -- カラムが存在しない場合は追加
        ALTER TABLE group_weekly_rates_backup 
        ADD COLUMN IF NOT EXISTS daily_rate_group TEXT;
        
        RAISE NOTICE 'Added daily_rate_group column to backup table';
    END IF;
    
    -- group_name カラムが存在するかチェック
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'group_weekly_rates_backup' 
        AND column_name = 'group_name'
    ) INTO col_exists;
    
    IF col_exists THEN
        -- group_name が存在する場合は daily_rate_group にデータを移行
        UPDATE group_weekly_rates_backup 
        SET daily_rate_group = group_name 
        WHERE daily_rate_group IS NULL AND group_name IS NOT NULL;
        
        RAISE NOTICE 'Migrated group_name to daily_rate_group in backup table';
    END IF;
END;
$$;

-- 2. メインテーブルの構造も確認・修正
DO $$
DECLARE
    col_exists BOOLEAN;
BEGIN
    -- daily_rate_group カラムが存在するかチェック
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'group_weekly_rates' 
        AND column_name = 'daily_rate_group'
    ) INTO col_exists;
    
    IF NOT col_exists THEN
        -- カラムが存在しない場合は追加
        ALTER TABLE group_weekly_rates 
        ADD COLUMN IF NOT EXISTS daily_rate_group TEXT;
        
        RAISE NOTICE 'Added daily_rate_group column to main table';
    END IF;
    
    -- group_name カラムが存在するかチェック
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'group_weekly_rates' 
        AND column_name = 'group_name'
    ) INTO col_exists;
    
    IF col_exists THEN
        -- group_name が存在する場合は daily_rate_group にデータを移行
        UPDATE group_weekly_rates 
        SET daily_rate_group = group_name 
        WHERE daily_rate_group IS NULL AND group_name IS NOT NULL;
        
        RAISE NOTICE 'Migrated group_name to daily_rate_group in main table';
    END IF;
END;
$$;

-- 3. 構造修正完了確認
SELECT 
    'Table structure fix completed' as status,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'group_weekly_rates') as main_columns,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'group_weekly_rates_backup') as backup_columns;
