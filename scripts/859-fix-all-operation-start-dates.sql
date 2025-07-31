-- 全user_nftsの運用開始日を正しく修正

-- 運用開始日の正しい計算関数
CREATE OR REPLACE FUNCTION calculate_correct_operation_start_date(purchase_date timestamp with time zone)
RETURNS timestamp with time zone AS $$
DECLARE
    purchase_dow integer;
    days_to_next_monday integer;
    next_monday timestamp with time zone;
    operation_start timestamp with time zone;
BEGIN
    -- 購入日の曜日を取得 (0=日曜, 1=月曜, ..., 6=土曜)
    purchase_dow := EXTRACT(DOW FROM purchase_date);
    
    -- 購入日の翌週の月曜日までの日数計算
    days_to_next_monday := CASE 
        WHEN purchase_dow = 0 THEN 1  -- 日曜日なら翌日(月曜)
        WHEN purchase_dow = 1 THEN 7  -- 月曜日なら1週間後
        WHEN purchase_dow = 2 THEN 6  -- 火曜日なら6日後
        WHEN purchase_dow = 3 THEN 5  -- 水曜日なら5日後
        WHEN purchase_dow = 4 THEN 4  -- 木曜日なら4日後
        WHEN purchase_dow = 5 THEN 3  -- 金曜日なら3日後
        WHEN purchase_dow = 6 THEN 2  -- 土曜日なら2日後
    END;
    
    -- 翌週の月曜日を計算
    next_monday := purchase_date + (days_to_next_monday || ' days')::interval;
    
    -- 翌々週の月曜日（運用開始日）を計算
    operation_start := next_monday + '7 days'::interval;
    
    RETURN operation_start;
END;
$$ LANGUAGE plpgsql;

-- 全user_nftsの運用開始日を正しく修正
UPDATE user_nfts 
SET operation_start_date = calculate_correct_operation_start_date(purchase_date)
WHERE is_active = true;

-- 修正結果確認（サンプル）
SELECT 
    u.name,
    u.user_id,
    TO_CHAR(un.purchase_date, 'YYYY/MM/DD (Dy)') as purchase_date,
    TO_CHAR(un.operation_start_date, 'YYYY/MM/DD (Dy)') as operation_date
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE u.name IN ('サカイユカ2', 'サカイユカ3')
  AND un.is_active = true
ORDER BY u.name;

-- 関数削除
DROP FUNCTION calculate_correct_operation_start_date(timestamp with time zone);