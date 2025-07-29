-- group_weekly_ratesテーブルの完全構造確認

-- 1. テーブル構造詳細確認
SELECT 
    '📋 テーブル構造詳細' as section,
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates' 
ORDER BY ordinal_position;

-- 2. 制約確認（正しいカラム名使用）
SELECT 
    '🔒 制約確認' as section,
    conname as constraint_name,
    contype as constraint_type,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'group_weekly_rates'::regclass;

-- 3. インデックス確認
SELECT 
    '📇 インデックス確認' as section,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'group_weekly_rates';

-- 4. 既存データ確認
SELECT 
    '📊 既存データ確認' as section,
    COUNT(*) as total_records,
    COUNT(DISTINCT group_id) as unique_groups,
    COUNT(DISTINCT week_start_date) as unique_weeks
FROM group_weekly_rates;

-- 5. group_idの値確認
SELECT 
    '🔍 group_id値確認' as section,
    group_id,
    COUNT(*) as count
FROM group_weekly_rates
GROUP BY group_id
ORDER BY group_id;
