-- 運用開始日の詳細調査（日本時間対応）
SELECT 
    operation_start_date,
    operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo' as jst_operation_start,
    EXTRACT(DOW FROM operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo') as jst_day_of_week,
    TO_CHAR(operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo', 'Day') as jst_day_name,
    TO_CHAR(operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo', 'YYYY-MM-DD') as jst_formatted_date,
    COUNT(*) as nft_count,
    COUNT(DISTINCT user_id) as user_count
FROM user_nfts 
WHERE is_active = true
GROUP BY operation_start_date
ORDER BY nft_count DESC, operation_start_date
LIMIT 10;

-- 購入日と運用開始日の関係を日本時間で確認
SELECT 
    purchase_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo' as jst_purchase_date,
    operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo' as jst_operation_start,
    (operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date - 
    (purchase_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date as wait_days,
    EXTRACT(DOW FROM purchase_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo') as jst_purchase_dow,
    EXTRACT(DOW FROM operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo') as jst_operation_dow,
    TO_CHAR(purchase_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo', 'Day') as jst_purchase_day_name,
    TO_CHAR(operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo', 'Day') as jst_operation_day_name,
    COUNT(*) as count
FROM user_nfts 
WHERE is_active = true
GROUP BY 
    purchase_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo',
    operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo'
ORDER BY count DESC
LIMIT 5;

-- 月曜日チェック（日本時間）
SELECT 
    'JST Monday Check' as check_type,
    COUNT(*) as total_nfts,
    COUNT(CASE WHEN EXTRACT(DOW FROM operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo') = 1 THEN 1 END) as monday_starts_jst,
    COUNT(CASE WHEN EXTRACT(DOW FROM operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo') != 1 THEN 1 END) as non_monday_starts_jst,
    ROUND(
        COUNT(CASE WHEN EXTRACT(DOW FROM operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo') = 1 THEN 1 END) * 100.0 / COUNT(*), 
        2
    ) as monday_percentage_jst
FROM user_nfts 
WHERE is_active = true;
