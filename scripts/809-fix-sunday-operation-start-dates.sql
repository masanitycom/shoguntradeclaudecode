-- 日曜日開始の運用開始日を月曜日に修正

SELECT '=== FIXING SUNDAY OPERATION START DATES ===' as section;

-- 1. 日曜日開始のレコード数を確認
SELECT 'Sunday operation starts to fix:' as info;
SELECT 
    COUNT(*) as sunday_starts,
    MIN(operation_start_date) as earliest_sunday,
    MAX(operation_start_date) as latest_sunday
FROM user_nfts
WHERE EXTRACT(DOW FROM operation_start_date) = 0;

-- 2. 影響を受けるユーザーの詳細
SELECT 'Users with Sunday starts (sample):' as info;
SELECT 
    un.id,
    u.name,
    u.email,
    n.name as nft_name,
    un.operation_start_date,
    TO_CHAR(un.operation_start_date, 'YYYY-MM-DD DY') as current_date,
    un.operation_start_date + INTERVAL '1 day' as new_monday_date,
    TO_CHAR(un.operation_start_date + INTERVAL '1 day', 'YYYY-MM-DD DY') as new_date
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE EXTRACT(DOW FROM un.operation_start_date) = 0
ORDER BY un.operation_start_date
LIMIT 10;

-- 3. 日曜日の運用開始日を月曜日に変更
SELECT 'Updating Sunday starts to Monday...' as action;
UPDATE user_nfts
SET 
    operation_start_date = operation_start_date + INTERVAL '1 day',
    updated_at = NOW()
WHERE EXTRACT(DOW FROM operation_start_date) = 0;

-- 4. 更新結果確認
SELECT 'Update results:' as info;
SELECT 
    TO_CHAR(operation_start_date, 'DY') as day_of_week,
    COUNT(*) as count
FROM user_nfts
WHERE operation_start_date IS NOT NULL
GROUP BY TO_CHAR(operation_start_date, 'DY'), EXTRACT(DOW FROM operation_start_date)
ORDER BY EXTRACT(DOW FROM operation_start_date);

SELECT '=== FIX COMPLETE - All Sunday starts moved to Monday ===' as status;