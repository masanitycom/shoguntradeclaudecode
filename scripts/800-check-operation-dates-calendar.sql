-- 運用開始日の曜日確認と日本時間カレンダーチェック
-- 既存データを確認してから修正方針を決定

-- 1. 現在の運用開始日を日本時間で確認
SELECT 'Current operation start dates (JST)' as info;
SELECT 
    u.name as user_name,
    n.name as nft_name,
    un.purchase_date,
    un.operation_start_date,
    -- UTC時間を日本時間に変換
    (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date as jst_operation_date,
    -- 日本時間での曜日を確認（0=日曜日、1=月曜日）
    EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) as jst_day_of_week,
    CASE EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date)
        WHEN 0 THEN '日曜日'
        WHEN 1 THEN '月曜日'
        WHEN 2 THEN '火曜日'
        WHEN 3 THEN '水曜日'
        WHEN 4 THEN '木曜日'
        WHEN 5 THEN '金曜日'
        WHEN 6 THEN '土曜日'
    END as jst_day_name,
    (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date - un.purchase_date::date as days_difference
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true 
  AND un.operation_start_date IS NOT NULL
ORDER BY un.purchase_date DESC;

-- 2. 月曜日以外の運用開始日を特定
SELECT 'Non-Monday operation dates that need fixing' as info;
SELECT 
    COUNT(*) as total_non_monday,
    COUNT(CASE WHEN EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) = 0 THEN 1 END) as sunday_count,
    COUNT(CASE WHEN EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) = 2 THEN 1 END) as tuesday_count,
    COUNT(CASE WHEN EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) = 3 THEN 1 END) as wednesday_count,
    COUNT(CASE WHEN EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) = 4 THEN 1 END) as thursday_count,
    COUNT(CASE WHEN EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) = 5 THEN 1 END) as friday_count,
    COUNT(CASE WHEN EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) = 6 THEN 1 END) as saturday_count
FROM user_nfts un
WHERE un.is_active = true 
  AND un.operation_start_date IS NOT NULL
  AND EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) != 1;

-- 3. 正しい運用開始日を計算（購入日+14日の次の月曜日、日本時間）
CREATE OR REPLACE FUNCTION calculate_correct_operation_start_date_jst(purchase_date DATE)
RETURNS TIMESTAMP WITH TIME ZONE
LANGUAGE plpgsql
AS $$
DECLARE
    waiting_end_date DATE;
    jst_day_of_week INTEGER;
    correct_monday_date DATE;
    result_timestamp TIMESTAMP WITH TIME ZONE;
BEGIN
    -- 購入日から14日後
    waiting_end_date := purchase_date + INTERVAL '14 days';
    
    -- その日の曜日を取得（0=日曜日、1=月曜日）
    jst_day_of_week := EXTRACT(DOW FROM waiting_end_date);
    
    -- 次の月曜日を計算
    IF jst_day_of_week = 1 THEN
        -- すでに月曜日の場合はその日
        correct_monday_date := waiting_end_date;
    ELSE
        -- 次の月曜日まで進める
        correct_monday_date := waiting_end_date + INTERVAL (((8 - jst_day_of_week) % 7) || ' days');
    END IF;
    
    -- 日本時間の00:00:00として設定し、UTCに変換
    result_timestamp := (correct_monday_date || ' 00:00:00')::timestamp AT TIME ZONE 'Asia/Tokyo';
    
    RETURN result_timestamp;
END;
$$;

-- 4. 修正が必要なデータのプレビュー
SELECT 'Preview of corrections needed' as info;
SELECT 
    u.name as user_name,
    n.name as nft_name,
    un.purchase_date,
    un.operation_start_date as current_operation_date,
    (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date as current_jst_date,
    CASE EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date)
        WHEN 0 THEN '日曜日' WHEN 1 THEN '月曜日' WHEN 2 THEN '火曜日'
        WHEN 3 THEN '水曜日' WHEN 4 THEN '木曜日' WHEN 5 THEN '金曜日' 
        WHEN 6 THEN '土曜日'
    END as current_day_name,
    calculate_correct_operation_start_date_jst(un.purchase_date::date) as correct_operation_date,
    (calculate_correct_operation_start_date_jst(un.purchase_date::date) AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date as correct_jst_date,
    '月曜日' as correct_day_name
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true 
  AND un.operation_start_date IS NOT NULL
  AND EXTRACT(DOW FROM (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date) != 1
ORDER BY un.purchase_date DESC;

-- 5. カレンダー確認用：2025年の特定日付の曜日チェック
SELECT 'Calendar verification for 2025' as info;
SELECT 
    date_val::date as calendar_date,
    EXTRACT(DOW FROM date_val) as dow,
    CASE EXTRACT(DOW FROM date_val)
        WHEN 0 THEN '日曜日' WHEN 1 THEN '月曜日' WHEN 2 THEN '火曜日'
        WHEN 3 THEN '水曜日' WHEN 4 THEN '木曜日' WHEN 5 THEN '金曜日' 
        WHEN 6 THEN '土曜日'
    END as day_name
FROM (VALUES 
    ('2025-05-25'::date),  -- 現在の運用開始日の例
    ('2025-05-26'::date),  -- 月曜日
    ('2025-06-08'::date),  -- 現在の運用開始日の例
    ('2025-06-09'::date)   -- 月曜日
) AS dates(date_val);