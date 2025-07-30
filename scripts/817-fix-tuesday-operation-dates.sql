-- 火曜日の運用開始日を月曜日に修正

SELECT '=== FIXING TUESDAY OPERATION START DATES ===' as section;

-- 1. 火曜日開始のレコード数を確認
SELECT 'Tuesday operation starts to fix:' as info;
SELECT 
    COUNT(*) as tuesday_starts,
    MIN(operation_start_date) as earliest_tuesday,
    MAX(operation_start_date) as latest_tuesday
FROM user_nfts
WHERE EXTRACT(DOW FROM operation_start_date) = 2;  -- 火曜日

-- 2. 影響を受けるユーザーの詳細
SELECT 'Users with Tuesday starts (before fix):' as info;
SELECT 
    un.id,
    u.name,
    u.email,
    n.name as nft_name,
    un.operation_start_date as current_date,
    TO_CHAR(un.operation_start_date, 'YYYY-MM-DD DY') as current_formatted,
    un.operation_start_date - INTERVAL '1 day' as new_monday_date,
    TO_CHAR(un.operation_start_date - INTERVAL '1 day', 'YYYY-MM-DD DY') as new_formatted
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE EXTRACT(DOW FROM un.operation_start_date) = 2  -- 火曜日
  AND un.is_active = true
ORDER BY un.operation_start_date
LIMIT 10;

-- 3. 火曜日の運用開始日を月曜日に変更
SELECT 'Updating Tuesday starts to Monday...' as action;
UPDATE user_nfts
SET 
    operation_start_date = operation_start_date - INTERVAL '1 day',
    updated_at = NOW()
WHERE EXTRACT(DOW FROM operation_start_date) = 2;  -- 火曜日

-- 4. 更新結果確認
SELECT 'Update results - day of week distribution:' as info;
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
    COUNT(*) as count
FROM user_nfts
WHERE operation_start_date IS NOT NULL
  AND is_active = true
GROUP BY EXTRACT(DOW FROM operation_start_date)
ORDER BY EXTRACT(DOW FROM operation_start_date);

-- 5. 修正後の確認
SELECT 'After fix - should show no Tuesday starts:' as info;
SELECT COUNT(*) as tuesday_count
FROM user_nfts
WHERE EXTRACT(DOW FROM operation_start_date) = 2;  -- 火曜日

SELECT '=== FIX COMPLETE - All Tuesday starts moved to Monday ===' as status;