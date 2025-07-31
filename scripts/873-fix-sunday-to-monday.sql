-- 日曜日開始を月曜日開始に修正

SELECT '=== 日曜日開始を月曜日に修正 ===' as section;

-- 1. 日曜日から運用開始のユーザーを月曜日に修正
SELECT '日曜日開始を月曜日に修正中...' as fixing;
UPDATE user_nfts 
SET operation_start_date = operation_start_date + INTERVAL '1 day'
WHERE is_active = true
  AND EXTRACT(DOW FROM operation_start_date) = 0;  -- 日曜日

-- 2. 修正結果確認
SELECT '修正後の運用開始日曜日分布:' as after_fix;
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

-- 3. サンプルユーザーの最終確認
SELECT 'サンプルユーザーの最終確認:' as sample_check;
SELECT 
    u.name,
    u.user_id,
    TO_CHAR(un.purchase_date, 'YYYY/MM/DD (Dy)') as purchase_formatted,
    TO_CHAR(un.operation_start_date, 'YYYY/MM/DD (Dy)') as operation_formatted
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE un.is_active = true
  AND (u.name LIKE '%サカイ%' OR u.name LIKE '%ヤタガワ%')
ORDER BY u.name
LIMIT 10;

SELECT '=== 全ユーザー月曜日開始修正完了 ===' as completed;