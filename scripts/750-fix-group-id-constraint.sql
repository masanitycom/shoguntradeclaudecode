-- group_weekly_ratesテーブルのgroup_id制約を修正

-- 1. 現在のテーブル構造を詳細確認
SELECT 
    '=== group_weekly_rates テーブル詳細構造 ===' as section,
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns
WHERE table_name = 'group_weekly_rates'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. group_idカラムをNULL許可に変更
DO $$
BEGIN
    -- group_idカラムをNULL許可に変更
    ALTER TABLE group_weekly_rates ALTER COLUMN group_id DROP NOT NULL;
    RAISE NOTICE 'group_idカラムをNULL許可に変更しました';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'group_id制約変更エラー: %', SQLERRM;
END $$;

-- 3. 既存の不完全なデータを削除
DO $$
BEGIN
    DELETE FROM group_weekly_rates WHERE group_name IS NULL OR weekly_rate IS NULL;
    RAISE NOTICE '不完全なデータを削除しました';
END $$;

-- 4. 修正後のテーブル構造確認
SELECT 
    '=== 修正後テーブル構造 ===' as section,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'group_weekly_rates'
AND table_schema = 'public'
ORDER BY ordinal_position;
