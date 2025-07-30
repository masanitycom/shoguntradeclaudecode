-- 運用開始日の曜日分布調査

SELECT '=== OPERATION START DATE ANALYSIS ===' as section;

-- 1. 運用開始日の曜日別集計
SELECT 'Operation start dates by day of week:' as info;
SELECT 
    TO_CHAR(operation_start_date, 'Day') as day_of_week,
    TO_CHAR(operation_start_date, 'DY') as day_short,
    EXTRACT(DOW FROM operation_start_date) as day_number,
    COUNT(*) as count,
    STRING_AGG(DISTINCT u.name, ', ' ORDER BY u.name) as user_names
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE operation_start_date IS NOT NULL
GROUP BY TO_CHAR(operation_start_date, 'Day'), 
         TO_CHAR(operation_start_date, 'DY'),
         EXTRACT(DOW FROM operation_start_date)
ORDER BY EXTRACT(DOW FROM operation_start_date);

-- 2. 2025/2/11（火曜日）開始の具体的なユーザー
SELECT 'Users starting on Tuesday 2025/2/11:' as info;
SELECT 
    un.id,
    u.name,
    u.email,
    n.name as nft_name,
    un.purchase_date,
    un.operation_start_date,
    un.operation_start_date - un.purchase_date as days_until_start
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.operation_start_date = '2025-02-11'
ORDER BY u.name;

-- 3. 購入日から運用開始日までの日数分析
SELECT 'Days between purchase and operation start:' as info;
SELECT 
    un.operation_start_date - un.purchase_date as days_gap,
    COUNT(*) as count,
    STRING_AGG(u.name || ' (' || TO_CHAR(un.operation_start_date, 'YYYY-MM-DD DY') || ')', ', ' ORDER BY u.name) as users_and_days
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE un.operation_start_date IS NOT NULL
GROUP BY un.operation_start_date - un.purchase_date
ORDER BY days_gap;

-- 4. 曜日別の運用開始ルール確認
SELECT 'Operation start day patterns:' as info;
SELECT 
    TO_CHAR(purchase_date, 'DY') as purchase_day,
    TO_CHAR(operation_start_date, 'DY') as start_day,
    COUNT(*) as count,
    MIN(operation_start_date - purchase_date) as min_days,
    MAX(operation_start_date - purchase_date) as max_days,
    AVG(operation_start_date - purchase_date) as avg_days
FROM user_nfts
WHERE operation_start_date IS NOT NULL
GROUP BY TO_CHAR(purchase_date, 'DY'), TO_CHAR(operation_start_date, 'DY')
ORDER BY COUNT(*) DESC;

SELECT 'Analysis complete - Check if operation start dates need adjustment' as conclusion;