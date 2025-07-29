-- まずテーブル構造を確認
SELECT 
    '📋 daily_rewards テーブル構造' as section,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' AND table_schema = 'public'
ORDER BY ordinal_position;

-- バックアップテーブル構造確認
SELECT 
    '📋 backup テーブル構造' as section,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'emergency_cleanup_backup_20250704' AND table_schema = 'public'
ORDER BY ordinal_position;
