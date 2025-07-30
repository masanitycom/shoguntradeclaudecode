-- 日曜日の運用開始日を月曜日に修正する実行スクリプト
-- 141件の修正対象を確認済み

-- トランザクション開始
BEGIN;

-- 修正前の状態を表示
SELECT '修正前の状態' as status;
SELECT 
    COUNT(*) as total_records,
    COUNT(CASE WHEN EXTRACT(DOW FROM (operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) = 0 THEN 1 END) as sunday_count,
    COUNT(CASE WHEN EXTRACT(DOW FROM (operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) = 1 THEN 1 END) as monday_count
FROM user_nfts 
WHERE is_active = true 
  AND operation_start_date IS NOT NULL;

-- 日曜日の運用開始日を1日後（月曜日）に修正
UPDATE user_nfts
SET 
    operation_start_date = operation_start_date + INTERVAL '1 day',
    updated_at = NOW()
WHERE is_active = true 
  AND operation_start_date IS NOT NULL
  AND EXTRACT(DOW FROM (operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) = 0;

-- 修正件数を確認
SELECT '修正件数' as status, COUNT(*) as updated_count
FROM user_nfts
WHERE is_active = true 
  AND operation_start_date IS NOT NULL
  AND updated_at >= NOW() - INTERVAL '1 minute';

-- 修正後の状態を確認
SELECT '修正後の状態' as status;
SELECT 
    COUNT(*) as total_records,
    COUNT(CASE WHEN EXTRACT(DOW FROM (operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) = 0 THEN 1 END) as sunday_count,
    COUNT(CASE WHEN EXTRACT(DOW FROM (operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) = 1 THEN 1 END) as monday_count
FROM user_nfts 
WHERE is_active = true 
  AND operation_start_date IS NOT NULL;

-- 修正後のサンプルデータ確認（10件）
SELECT '修正後のサンプル確認' as status;
SELECT 
    u.name as user_name,
    n.name as nft_name,
    un.purchase_date,
    un.operation_start_date,
    (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date as jst_operation_date,
    CASE EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date)
        WHEN 0 THEN '日曜日' WHEN 1 THEN '月曜日' WHEN 2 THEN '火曜日'
        WHEN 3 THEN '水曜日' WHEN 4 THEN '木曜日' WHEN 5 THEN '金曜日' 
        WHEN 6 THEN '土曜日'
    END as day_name
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true 
  AND un.operation_start_date IS NOT NULL
  AND un.updated_at >= NOW() - INTERVAL '1 minute'
ORDER BY un.purchase_date DESC
LIMIT 10;

-- 問題なければCOMMIT、問題があればROLLBACKしてください
-- COMMIT;
-- ROLLBACK;