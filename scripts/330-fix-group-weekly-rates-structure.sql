-- group_weekly_rates テーブルの構造を修正

-- 現在の構造を確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates' 
    AND column_name = 'week_number';

-- week_number カラムをオプショナルにする
DO $$
BEGIN
    -- week_number カラムが NOT NULL の場合、NULL を許可するように変更
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'group_weekly_rates' 
            AND column_name = 'week_number' 
            AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE group_weekly_rates 
        ALTER COLUMN week_number DROP NOT NULL;
        
        RAISE NOTICE 'week_number カラムを NULL 許可に変更しました';
    ELSE
        RAISE NOTICE 'week_number カラムは既に NULL 許可です';
    END IF;
END $$;

-- 週番号を自動計算する関数を作成
CREATE OR REPLACE FUNCTION calculate_week_number(start_date DATE)
RETURNS INTEGER AS $$
BEGIN
    RETURN EXTRACT(WEEK FROM start_date);
END;
$$ LANGUAGE plpgsql;

-- 既存のレコードの week_number を更新
UPDATE group_weekly_rates 
SET week_number = calculate_week_number(week_start_date::date)
WHERE week_number IS NULL;

-- デフォルト値を設定（新しいレコード用）
ALTER TABLE group_weekly_rates 
ALTER COLUMN week_number SET DEFAULT EXTRACT(WEEK FROM CURRENT_DATE);

-- 修正完了の確認
SELECT 
    column_name,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates' 
    AND column_name = 'week_number';

-- 更新されたレコード数を確認
SELECT 
    COUNT(*) as total_records,
    COUNT(week_number) as records_with_week_number,
    COUNT(*) - COUNT(week_number) as null_week_numbers
FROM group_weekly_rates;

SELECT 'group_weekly_rates テーブルの week_number カラムを修正しました' as status;
