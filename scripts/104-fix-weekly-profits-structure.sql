-- weekly_profitsテーブル構造の確認と修正

-- 1. 既存テーブル構造を確認
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'weekly_profits' 
ORDER BY ordinal_position;

-- 2. 不足しているカラムを追加
ALTER TABLE weekly_profits 
ADD COLUMN IF NOT EXISTS week_end_date DATE;

-- 3. week_end_dateが空の場合は週末日付を自動計算
UPDATE weekly_profits 
SET week_end_date = week_start_date + INTERVAL '6 days'
WHERE week_end_date IS NULL;

-- 4. week_end_dateをNOT NULLに変更
ALTER TABLE weekly_profits 
ALTER COLUMN week_end_date SET NOT NULL;

-- 5. 確認
SELECT * FROM weekly_profits ORDER BY week_start_date;

SELECT 'Weekly profits structure fixed' as status;
