-- 現在の運用開始日状況を確認

SELECT '=== CURRENT OPERATION START DATES ===' as section;

-- 1. 曜日別の分布
SELECT 'Distribution by day of week:' as info;
SELECT 
    EXTRACT(DOW FROM operation_start_date) as day_of_week,
    CASE EXTRACT(DOW FROM operation_start_date)
        WHEN 0 THEN '日曜日'
        WHEN 1 THEN '月曜日'
        WHEN 2 THEN '火曜日'
        WHEN 3 THEN '水曜日'
        WHEN 4 THEN '木曜日'
        WHEN 5 THEN '金曜日'
        WHEN 6 THEN '土曜日'
    END as day_name,
    COUNT(*) as count,
    MIN(operation_start_date) as earliest_date,
    MAX(operation_start_date) as latest_date
FROM user_nfts
WHERE operation_start_date IS NOT NULL
  AND is_active = true
GROUP BY EXTRACT(DOW FROM operation_start_date)
ORDER BY EXTRACT(DOW FROM operation_start_date);

-- 2. 火曜日開始のユーザー詳細
SELECT 'Tuesday operation starts (問題のデータ):' as info;
SELECT 
    un.id,
    u.name,
    u.email,
    n.name as nft_name,
    un.purchase_date,
    un.operation_start_date,
    TO_CHAR(un.operation_start_date, 'YYYY-MM-DD DY') as formatted_date
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE EXTRACT(DOW FROM un.operation_start_date) = 2  -- 火曜日
  AND un.is_active = true
ORDER BY un.operation_start_date
LIMIT 10;

-- 3. 運用開始日がNULLのユーザー
SELECT 'Users with NULL operation start date:' as info;
SELECT COUNT(*) as null_operation_count
FROM user_nfts
WHERE operation_start_date IS NULL
  AND is_active = true;

SELECT '=== ANALYSIS COMPLETE ===' as status;