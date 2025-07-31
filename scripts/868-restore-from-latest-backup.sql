-- 最新バックアップからの復元

SELECT '=== 最新バックアップから復元 ===' as section;

-- 1. 最新のuser_nftsバックアップ確認
SELECT '最新バックアップの内容確認:' as check_latest;
SELECT 
    COUNT(*) as total_records,
    MIN(created_at) as oldest_record,
    MAX(created_at) as newest_record
FROM user_nfts_backup_20250730;

-- 2. サンプルデータ確認
SELECT 'サンプルデータ確認:' as sample_check;
SELECT 
    un.user_id,
    u.name,
    u.user_id as user_login_id,
    un.purchase_date,
    un.operation_start_date,
    un.current_investment,
    un.created_at
FROM user_nfts_backup_20250730 un
JOIN users u ON un.user_id = u.id
WHERE un.is_active = true
ORDER BY un.created_at DESC
LIMIT 10;

-- 3. user_nftsバックアップからの復元実行
SELECT 'user_nftsデータ復元実行中...' as restore_action;
INSERT INTO user_nfts 
SELECT * FROM user_nfts_backup_20250730;

-- 4. 復元結果確認
SELECT '復元完了確認:' as verification;
SELECT 
    COUNT(*) as restored_records
FROM user_nfts;

SELECT 'サカイユカユーザーの復元確認:' as sakai_check;
SELECT 
    u.name,
    u.user_id,
    un.purchase_date,
    un.operation_start_date,
    un.current_investment
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE u.name LIKE '%サカイ%'
  AND un.is_active = true
ORDER BY u.name;

SELECT '=== 復元完了 ===' as completed;