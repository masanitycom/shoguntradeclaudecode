-- group_weekly_rates テーブルに必要な制約を追加

-- 既存の制約を確認
SELECT constraint_name, constraint_type 
FROM information_schema.table_constraints 
WHERE table_name = 'group_weekly_rates';

-- group_id と week_start_date の組み合わせでユニーク制約を追加
-- （既に存在する場合はエラーになるが、それは正常）
DO $$
BEGIN
    -- group_weekly_rates_unique 制約が存在しない場合のみ追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'group_weekly_rates' 
        AND constraint_name = 'group_weekly_rates_unique'
    ) THEN
        ALTER TABLE group_weekly_rates 
        ADD CONSTRAINT group_weekly_rates_unique 
        UNIQUE (group_id, week_start_date);
        
        RAISE NOTICE 'ユニーク制約 group_weekly_rates_unique を追加しました';
    ELSE
        RAISE NOTICE 'ユニーク制約 group_weekly_rates_unique は既に存在します';
    END IF;
END $$;

-- 制約追加後の確認
SELECT constraint_name, constraint_type 
FROM information_schema.table_constraints 
WHERE table_name = 'group_weekly_rates'
ORDER BY constraint_type, constraint_name;
