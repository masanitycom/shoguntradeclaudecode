-- 基本的な運用開始日の確認（最初の10件のみ）
SELECT 'Current operation start dates (JST) - First 10 records' as info;
SELECT 
    u.name as user_name,
    n.name as nft_name,
    un.purchase_date,
    un.operation_start_date,
    (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date as jst_operation_date,
    EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) as jst_day_of_week,
    CASE EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date)
        WHEN 0 THEN '日曜日'
        WHEN 1 THEN '月曜日'
        WHEN 2 THEN '火曜日'
        WHEN 3 THEN '水曜日'
        WHEN 4 THEN '木曜日'
        WHEN 5 THEN '金曜日'
        WHEN 6 THEN '土曜日'
    END as jst_day_name
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true 
  AND un.operation_start_date IS NOT NULL
ORDER BY un.purchase_date DESC
LIMIT 10;