-- グループ別週利設定テーブル構造を修正

-- 1. 既存のテーブル構造を確認
SELECT 
    '📊 現在のテーブル構造確認' as status,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates' 
ORDER BY ordinal_position;

-- 2. group_idカラムが存在しない場合は追加
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'group_weekly_rates' AND column_name = 'group_id'
    ) THEN
        ALTER TABLE group_weekly_rates ADD COLUMN group_id UUID;
        
        -- 既存データのgroup_idを設定
        UPDATE group_weekly_rates 
        SET group_id = daily_rate_groups.id
        FROM daily_rate_groups
        WHERE group_weekly_rates.group_name = daily_rate_groups.group_name;
        
        -- NOT NULL制約を追加
        ALTER TABLE group_weekly_rates ALTER COLUMN group_id SET NOT NULL;
        
        -- 外部キー制約を追加
        ALTER TABLE group_weekly_rates 
        ADD CONSTRAINT fk_group_weekly_rates_group_id 
        FOREIGN KEY (group_id) REFERENCES daily_rate_groups(id);
    END IF;
END $$;

-- 3. 複合ユニーク制約を追加（week_start_date + group_id）
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'unique_week_group'
    ) THEN
        ALTER TABLE group_weekly_rates 
        ADD CONSTRAINT unique_week_group 
        UNIQUE (week_start_date, group_id);
    END IF;
END $$;

-- 4. インデックスを追加
CREATE INDEX IF NOT EXISTS idx_group_weekly_rates_week_start 
ON group_weekly_rates(week_start_date);

CREATE INDEX IF NOT EXISTS idx_group_weekly_rates_group_id 
ON group_weekly_rates(group_id);

-- 5. 修正後のテーブル構造を確認
SELECT 
    '✅ 修正後のテーブル構造' as status,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates' 
ORDER BY ordinal_position;

-- 6. 制約を確認
SELECT 
    '🔒 テーブル制約確認' as status,
    conname as constraint_name,
    contype as constraint_type
FROM pg_constraint 
WHERE conrelid = 'group_weekly_rates'::regclass;
