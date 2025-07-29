-- テーブル構造の緊急修正

-- 1. group_weekly_ratesテーブルにgroup_nameカラムが存在しない場合は追加
DO $$
BEGIN
    -- group_nameカラムが存在するかチェック
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'group_weekly_rates' 
        AND column_name = 'group_name'
    ) THEN
        -- group_nameカラムを追加
        ALTER TABLE group_weekly_rates ADD COLUMN group_name TEXT;
        RAISE NOTICE 'group_nameカラムを追加しました';
    ELSE
        RAISE NOTICE 'group_nameカラムは既に存在します';
    END IF;
    
    -- group_idカラムが存在するかチェック
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'group_weekly_rates' 
        AND column_name = 'group_id'
    ) THEN
        -- group_idカラムを追加
        ALTER TABLE group_weekly_rates ADD COLUMN group_id UUID;
        RAISE NOTICE 'group_idカラムを追加しました';
    ELSE
        RAISE NOTICE 'group_idカラムは既に存在します';
    END IF;
    
    -- distribution_methodカラムが存在するかチェック
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'group_weekly_rates' 
        AND column_name = 'distribution_method'
    ) THEN
        -- distribution_methodカラムを追加
        ALTER TABLE group_weekly_rates ADD COLUMN distribution_method TEXT DEFAULT 'manual';
        RAISE NOTICE 'distribution_methodカラムを追加しました';
    ELSE
        RAISE NOTICE 'distribution_methodカラムは既に存在します';
    END IF;
    
    -- week_end_dateカラムが存在するかチェック
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'group_weekly_rates' 
        AND column_name = 'week_end_date'
    ) THEN
        -- week_end_dateカラムを追加
        ALTER TABLE group_weekly_rates ADD COLUMN week_end_date DATE;
        RAISE NOTICE 'week_end_dateカラムを追加しました';
    ELSE
        RAISE NOTICE 'week_end_dateカラムは既に存在します';
    END IF;
    
    -- created_atカラムが存在するかチェック
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'group_weekly_rates' 
        AND column_name = 'created_at'
    ) THEN
        -- created_atカラムを追加
        ALTER TABLE group_weekly_rates ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'created_atカラムを追加しました';
    ELSE
        RAISE NOTICE 'created_atカラムは既に存在します';
    END IF;
    
    -- updated_atカラムが存在するかチェック
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'group_weekly_rates' 
        AND column_name = 'updated_at'
    ) THEN
        -- updated_atカラムを追加
        ALTER TABLE group_weekly_rates ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'updated_atカラムを追加しました';
    ELSE
        RAISE NOTICE 'updated_atカラムは既に存在します';
    END IF;
END $$;

-- 2. 修正後のテーブル構造を確認
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates'
ORDER BY ordinal_position;
