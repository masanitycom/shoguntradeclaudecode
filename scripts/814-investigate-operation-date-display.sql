-- 運用開始日の表示問題を調査

SELECT '=== OPERATION DATE DISPLAY INVESTIGATION ===' as section;

-- 1. 現在のuser_nftsの運用開始日を確認
SELECT 'Current operation start dates in database:' as info;
SELECT 
    un.id,
    u.name,
    u.email,
    n.name as nft_name,
    un.operation_start_date,
    TO_CHAR(un.operation_start_date, 'YYYY-MM-DD DY') as date_with_day,
    EXTRACT(DOW FROM un.operation_start_date) as day_of_week_number,
    un.purchase_date,
    TO_CHAR(un.purchase_date, 'YYYY-MM-DD DY') as purchase_date_with_day
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true
ORDER BY un.operation_start_date
LIMIT 10;

-- 2. 特定のユーザーの詳細確認
SELECT 'Specific user operation dates:' as info;
SELECT 
    un.id,
    u.name,
    u.email,
    n.name as nft_name,
    un.purchase_date,
    un.operation_start_date,
    un.operation_start_date AT TIME ZONE 'UTC' as utc_time,
    un.operation_start_date AT TIME ZONE 'Asia/Tokyo' as jst_time,
    TO_CHAR(un.operation_start_date AT TIME ZONE 'Asia/Tokyo', 'YYYY-MM-DD DY HH24:MI:SS') as jst_formatted
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true
  AND n.name = 'SHOGUN NFT 1000 (Special)'
ORDER BY un.purchase_date
LIMIT 5;

-- 3. 曜日別の分布確認
SELECT 'Distribution by day of week:' as info;
SELECT 
    EXTRACT(DOW FROM un.operation_start_date) as day_of_week,
    TO_CHAR(un.operation_start_date, 'DY') as day_name,
    COUNT(*) as count,
    STRING_AGG(u.name, ', ' ORDER BY u.name) as users
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE un.is_active = true
  AND un.operation_start_date IS NOT NULL
GROUP BY EXTRACT(DOW FROM un.operation_start_date), TO_CHAR(un.operation_start_date, 'DY')
ORDER BY EXTRACT(DOW FROM un.operation_start_date);

-- 4. 2025/2/11 (火曜日) の確認
SELECT '2025-02-11 specific date check:' as info;
SELECT 
    un.id,
    u.name,
    u.email,
    un.operation_start_date,
    EXTRACT(DOW FROM un.operation_start_date) as day_of_week,
    un.purchase_date
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE DATE(un.operation_start_date) = '2025-02-11'
ORDER BY u.name;

SELECT '=== INVESTIGATION COMPLETE ===' as status;