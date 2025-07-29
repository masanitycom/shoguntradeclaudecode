-- バックアップテーブルの実際の構造を確認

-- 1. バックアップテーブルが存在するかチェック
SELECT 
    '=== バックアップテーブル存在確認 ===' as check_section,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'group_weekly_rates_backup')
        THEN '✅ group_weekly_rates_backup テーブルが存在します'
        ELSE '❌ group_weekly_rates_backup テーブルが存在しません'
    END as table_status;

-- 2. バックアップテーブルの構造を確認（存在する場合）
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'group_weekly_rates_backup') THEN
        RAISE NOTICE '=== バックアップテーブルのカラム構造 ===';
        
        -- カラム情報を表示
        PERFORM column_name, data_type, is_nullable
        FROM information_schema.columns 
        WHERE table_name = 'group_weekly_rates_backup'
        ORDER BY ordinal_position;
    END IF;
END $$;

-- 3. 実際のカラム一覧を取得
SELECT 
    '=== バックアップテーブルカラム一覧 ===' as info_section,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates_backup'
ORDER BY ordinal_position;

-- 4. バックアップデータ件数確認
SELECT 
    '=== バックアップデータ件数 ===' as count_section,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'group_weekly_rates_backup')
        THEN (SELECT COUNT(*) FROM group_weekly_rates_backup)::TEXT
        ELSE '0（テーブル未存在）'
    END as record_count;

-- 5. 通常の週利テーブル構造も確認
SELECT 
    '=== 通常の週利テーブル構造 ===' as normal_table_section,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates'
ORDER BY ordinal_position;
