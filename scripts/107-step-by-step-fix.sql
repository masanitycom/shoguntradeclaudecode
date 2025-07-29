-- 段階的にweekly_profitsテーブルを修正

-- 1. 現在のweekly_profitsテーブル構造を確認
SELECT 'Current weekly_profits structure:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'weekly_profits' 
ORDER BY ordinal_position;

-- 2. week_end_dateカラムを追加
SELECT 'Adding week_end_date column...' as info;
ALTER TABLE weekly_profits 
ADD COLUMN week_end_date DATE;

-- 3. 追加後の構造を確認
SELECT 'After adding week_end_date:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'weekly_profits' 
ORDER BY ordinal_position;

-- 4. 既存データがある場合、week_end_dateを計算
UPDATE weekly_profits 
SET week_end_date = week_start_date + INTERVAL '6 days'
WHERE week_end_date IS NULL;

-- 5. week_end_dateをNOT NULLに変更
ALTER TABLE weekly_profits 
ALTER COLUMN week_end_date SET NOT NULL;

-- 6. 最終確認
SELECT 'Final weekly_profits structure:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'weekly_profits' 
ORDER BY ordinal_position;

-- 7. データ確認
SELECT 'Current data in weekly_profits:' as info;
SELECT * FROM weekly_profits ORDER BY week_start_date;

SELECT 'Weekly profits table fixed successfully' as status;
