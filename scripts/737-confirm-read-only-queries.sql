-- 📋 実行予定のSQLが全て読み取り専用であることの確認

-- ✅ これらは全てSELECT文（読み取り専用）です
-- ❌ INSERT, UPDATE, DELETE, DROP, ALTER は一切含まれていません

-- 1. scripts/735-investigate-nft-operation-logic.sql の内容確認
/*
SELECT文のみ:
- SELECT u.name, un.purchase_date, un.operation_start_date...
- SELECT week_start_date, COUNT(*)...
- SELECT 'NFT運用開始日範囲'...
- WITH sample_purchases AS (SELECT...)
*/

-- 2. scripts/736-check-weekly-rates-coverage.sql の内容確認  
/*
SELECT文のみ:
- WITH nft_weeks AS (SELECT DISTINCT...)
- SELECT rate_status, COUNT(*)...
- SELECT DISTINCT operation_start_date...
*/

-- 🔒 データ保護の確認
SELECT 
    'user_nfts テーブル' as table_name,
    COUNT(*) as current_record_count,
    COUNT(CASE WHEN purchase_date IS NOT NULL THEN 1 END) as records_with_purchase_date,
    COUNT(CASE WHEN operation_start_date IS NOT NULL THEN 1 END) as records_with_operation_date
FROM user_nfts
WHERE is_active = true;

-- 📊 現在のデータ状況（変更前の記録）
SELECT 
    '実行前データ確認' as status,
    NOW() as check_time,
    (SELECT COUNT(*) FROM user_nfts WHERE is_active = true) as active_nfts,
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM group_weekly_rates) as weekly_rates
;
