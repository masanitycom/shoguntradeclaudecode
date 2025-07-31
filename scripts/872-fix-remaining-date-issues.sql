-- 残りの日付ズレ問題の修正

SELECT '=== 残りの日付ズレ修正 ===' as section;

-- 1. 火曜日から運用開始になっているユーザーを確認
SELECT '火曜日から運用開始のユーザー:' as tuesday_users;
SELECT 
    u.name,
    u.user_id,
    un.purchase_date,
    un.operation_start_date,
    EXTRACT(DOW FROM un.operation_start_date) as operation_dow,
    TO_CHAR(un.operation_start_date, 'YYYY/MM/DD (Dy)') as operation_formatted
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE un.is_active = true
  AND EXTRACT(DOW FROM un.operation_start_date) = 2  -- 火曜日
ORDER BY un.operation_start_date;

-- 2. 火曜日開始を月曜日開始に修正
SELECT '火曜日開始を月曜日に修正中...' as fixing;
UPDATE user_nfts 
SET operation_start_date = operation_start_date - INTERVAL '1 day'
WHERE is_active = true
  AND EXTRACT(DOW FROM operation_start_date) = 2;  -- 火曜日

-- 3. 修正結果確認
SELECT '修正後の確認:' as after_fix;
SELECT 
    u.name,
    u.user_id,
    TO_CHAR(un.purchase_date, 'YYYY/MM/DD (Dy)') as purchase_formatted,
    TO_CHAR(un.operation_start_date, 'YYYY/MM/DD (Dy)') as operation_formatted,
    EXTRACT(DOW FROM un.operation_start_date) as operation_dow
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE un.is_active = true
  AND (u.name LIKE '%サカイ%' OR u.name LIKE '%ヤタガワ%')
ORDER BY u.name;

-- 4. 全体の運用開始日の曜日分布確認
SELECT '運用開始日の曜日分布:' as dow_distribution;
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
WHERE is_active = true
GROUP BY EXTRACT(DOW FROM operation_start_date)
ORDER BY EXTRACT(DOW FROM operation_start_date);

SELECT '=== 日付ズレ修正完了 ===' as completed;