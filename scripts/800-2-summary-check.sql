-- 運用開始日の曜日別統計
SELECT 'Non-Monday operation dates summary' as info;
SELECT 
    COUNT(*) as total_active_nfts,
    COUNT(CASE WHEN EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) = 1 THEN 1 END) as monday_count,
    COUNT(CASE WHEN EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) != 1 THEN 1 END) as non_monday_count,
    COUNT(CASE WHEN EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) = 0 THEN 1 END) as sunday_count,
    COUNT(CASE WHEN EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) = 2 THEN 1 END) as tuesday_count,
    COUNT(CASE WHEN EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) = 3 THEN 1 END) as wednesday_count,
    COUNT(CASE WHEN EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) = 4 THEN 1 END) as thursday_count,
    COUNT(CASE WHEN EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) = 5 THEN 1 END) as friday_count,
    COUNT(CASE WHEN EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) = 6 THEN 1 END) as saturday_count
FROM user_nfts un
WHERE un.is_active = true 
  AND un.operation_start_date IS NOT NULL;