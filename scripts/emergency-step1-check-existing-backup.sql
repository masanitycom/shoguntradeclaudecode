-- 既存バックアップの確認
SELECT 'EXISTING BACKUP VERIFICATION' as status;

-- バックアップテーブルの存在確認
SELECT 
    schemaname,
    tablename,
    tableowner
FROM pg_tables 
WHERE tablename LIKE '%backup_emergency%'
ORDER BY tablename;

-- バックアップデータの件数確認
SELECT 'auth_users_backup_emergency' as table_name, COUNT(*) as record_count
FROM auth_users_backup_emergency
UNION ALL
SELECT 'users_backup_emergency', COUNT(*)
FROM users_backup_emergency
UNION ALL
SELECT 'user_nfts_backup_emergency', COUNT(*)
FROM user_nfts_backup_emergency
UNION ALL
SELECT 'daily_rewards_backup_emergency', COUNT(*)
FROM daily_rewards_backup_emergency
UNION ALL
SELECT 'nft_purchase_applications_backup_emergency', COUNT(*)
FROM nft_purchase_applications_backup_emergency;

-- バックアップ作成時刻確認（可能な場合）
SELECT 
    'BACKUP CREATED' as info,
    MIN(created_at) as earliest_backup,
    MAX(created_at) as latest_backup
FROM users_backup_emergency;