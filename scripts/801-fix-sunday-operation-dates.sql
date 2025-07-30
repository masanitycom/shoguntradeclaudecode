-- 日曜日の運用開始日を月曜日に修正するスクリプト
-- 実行前に必ずバックアップを取ること

-- 1. 修正対象の確認（実行前に必ず確認）
SELECT 'Records to be fixed (Sunday to Monday)' as info;
SELECT 
    un.id,
    u.name as user_name,
    n.name as nft_name,
    un.purchase_date,
    un.operation_start_date as current_operation_date,
    (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date as current_jst_date,
    un.operation_start_date + INTERVAL '1 day' as new_operation_date,
    ((un.operation_start_date + INTERVAL '1 day') AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date as new_jst_date
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true 
  AND un.operation_start_date IS NOT NULL
  AND EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) = 0  -- 日曜日
ORDER BY un.purchase_date DESC;

-- 2. バックアップ用のデータ取得（実行前に保存）
/*
SELECT 
    un.id,
    un.user_id,
    un.nft_id,
    un.purchase_date,
    un.operation_start_date,
    un.current_investment,
    un.total_earned,
    un.is_active,
    un.created_at,
    un.updated_at
FROM user_nfts un
WHERE un.is_active = true 
  AND un.operation_start_date IS NOT NULL
  AND EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) = 0;
*/

-- 3. 実際の修正（コメントアウトしてあるので、確認後に実行）
/*
BEGIN;

-- 日曜日の運用開始日を1日後（月曜日）に修正
UPDATE user_nfts
SET 
    operation_start_date = operation_start_date + INTERVAL '1 day',
    updated_at = NOW()
WHERE is_active = true 
  AND operation_start_date IS NOT NULL
  AND EXTRACT(DOW FROM (operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) = 0;

-- 修正結果の確認
SELECT 
    COUNT(*) as updated_count,
    'Updated Sunday operation dates to Monday' as action
FROM user_nfts
WHERE is_active = true 
  AND operation_start_date IS NOT NULL
  AND updated_at >= NOW() - INTERVAL '1 minute';

-- 問題なければCOMMIT、問題があればROLLBACK
-- COMMIT;
-- ROLLBACK;
*/

-- 4. 修正後の確認
/*
SELECT 'After fix - Day of week summary' as info;
SELECT 
    COUNT(*) as total_active_nfts,
    COUNT(CASE WHEN EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) = 1 THEN 1 END) as monday_count,
    COUNT(CASE WHEN EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) != 1 THEN 1 END) as non_monday_count
FROM user_nfts un
WHERE un.is_active = true 
  AND un.operation_start_date IS NOT NULL;
*/