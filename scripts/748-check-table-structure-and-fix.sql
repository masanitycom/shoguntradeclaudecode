-- group_weekly_ratesテーブルの構造確認と制約修正

-- 1. テーブル構造の確認
SELECT 
    '=== group_weekly_rates テーブル構造 ===' as section,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'group_weekly_rates'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. 既存の制約確認
SELECT 
    '=== 既存制約確認 ===' as section,
    tc.constraint_name,
    tc.constraint_type,
    string_agg(ccu.column_name, ', ') as columns
FROM information_schema.table_constraints tc
JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_name = 'group_weekly_rates'
AND tc.table_schema = 'public'
GROUP BY tc.constraint_name, tc.constraint_type
ORDER BY tc.constraint_type;

-- 3. テーブルが存在しない場合は作成
CREATE TABLE IF NOT EXISTS group_weekly_rates (
    id SERIAL PRIMARY KEY,
    week_start_date DATE NOT NULL,
    week_end_date DATE NOT NULL,
    group_name TEXT NOT NULL,
    weekly_rate NUMERIC(10,6) NOT NULL,
    monday_rate NUMERIC(10,6) NOT NULL DEFAULT 0,
    tuesday_rate NUMERIC(10,6) NOT NULL DEFAULT 0,
    wednesday_rate NUMERIC(10,6) NOT NULL DEFAULT 0,
    thursday_rate NUMERIC(10,6) NOT NULL DEFAULT 0,
    friday_rate NUMERIC(10,6) NOT NULL DEFAULT 0,
    distribution_method TEXT DEFAULT 'manual',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. ユニーク制約を安全に追加
DO $$
BEGIN
    -- 既存の制約を削除（存在する場合）
    BEGIN
        ALTER TABLE group_weekly_rates DROP CONSTRAINT IF EXISTS unique_week_group;
        RAISE NOTICE '既存制約を削除しました（存在した場合）';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '制約削除でエラー（問題なし）: %', SQLERRM;
    END;
    
    -- 重複データを削除
    DELETE FROM group_weekly_rates a USING group_weekly_rates b 
    WHERE a.id > b.id 
    AND a.week_start_date = b.week_start_date 
    AND a.group_name = b.group_name;
    
    -- ユニーク制約を追加
    ALTER TABLE group_weekly_rates 
    ADD CONSTRAINT unique_week_group 
    UNIQUE (week_start_date, group_name);
    
    RAISE NOTICE 'ユニーク制約 unique_week_group を正常に追加しました';
END $$;

-- 5. 制約追加後の確認
SELECT 
    '=== 制約追加後の確認 ===' as section,
    tc.constraint_name,
    tc.constraint_type,
    string_agg(ccu.column_name, ', ') as columns
FROM information_schema.table_constraints tc
JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_name = 'group_weekly_rates'
AND tc.table_schema = 'public'
GROUP BY tc.constraint_name, tc.constraint_type
ORDER BY tc.constraint_type;
