-- 緊急バックアップからの復元

SELECT '=== 緊急復元開始 ===' as section;

-- 1. バックアップテーブルの存在確認
SELECT 'バックアップテーブル確認:' as check_backup;
SELECT 
    table_name,
    '存在' as status
FROM information_schema.tables
WHERE table_schema = 'public'
  AND (
    table_name = 'user_nfts_backup_before_restore'
    OR table_name = 'users_backup_before_restore'
    OR table_name = 'daily_rewards_backup_before_restore'
  );

-- 2. 現在のuser_nftsを削除
SELECT '現在のuser_nftsデータ削除中...' as action;
DELETE FROM user_nfts;

-- 3. バックアップからuser_nftsを復元
SELECT 'user_nftsデータ復元中...' as restore_action;
INSERT INTO user_nfts 
SELECT * FROM user_nfts_backup_before_restore;

-- 4. 復元結果確認
SELECT '復元結果確認:' as verification;
SELECT 
    COUNT(*) as total_restored_nfts
FROM user_nfts;

SELECT 'サンプルユーザーの復元確認:' as sample_check;
SELECT 
    u.name,
    u.user_id,
    un.purchase_date,
    un.operation_start_date,
    un.current_investment,
    un.created_at
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE un.is_active = true
ORDER BY un.created_at DESC
LIMIT 10;

SELECT '=== 緊急復元完了 ===' as completed;