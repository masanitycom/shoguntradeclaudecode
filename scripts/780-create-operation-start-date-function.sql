-- NFT運用開始日の自動計算機能
-- 購入日から2週間後の月曜日を日本時間で計算

-- 日本時間での運用開始日計算関数
CREATE OR REPLACE FUNCTION calculate_operation_start_date(purchase_date DATE)
RETURNS DATE
LANGUAGE plpgsql
AS $$
DECLARE
    jst_purchase_date DATE;
    waiting_end_date DATE;
    operation_start_date DATE;
    day_of_week INTEGER;
BEGIN
    -- 購入日を日本時間で取得
    jst_purchase_date := purchase_date;
    
    -- 2週間（14日）の待機期間を追加
    waiting_end_date := jst_purchase_date + INTERVAL '14 days';
    
    -- 待機期間終了日の曜日を取得（0=日曜日, 1=月曜日, 6=土曜日）
    day_of_week := EXTRACT(DOW FROM waiting_end_date);
    
    -- 次の月曜日を計算
    IF day_of_week = 1 THEN
        -- すでに月曜日の場合はその日から開始
        operation_start_date := waiting_end_date::DATE;
    ELSE
        -- 次の月曜日まで進める
        -- 月曜日(1)まで進める日数を計算
        operation_start_date := (waiting_end_date + INTERVAL (((8 - day_of_week) % 7) || ' days'))::DATE;
    END IF;
    
    RETURN operation_start_date;
END;
$$;

-- user_nftsテーブルにoperation_start_dateを自動設定するトリガー関数
CREATE OR REPLACE FUNCTION set_operation_start_date()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- 新規作成時にoperation_start_dateが未設定の場合は自動計算
    IF NEW.operation_start_date IS NULL AND NEW.purchase_date IS NOT NULL THEN
        NEW.operation_start_date := calculate_operation_start_date(NEW.purchase_date);
    END IF;
    
    -- purchase_dateが更新された場合は自動再計算
    IF TG_OP = 'UPDATE' AND OLD.purchase_date IS DISTINCT FROM NEW.purchase_date AND NEW.purchase_date IS NOT NULL THEN
        NEW.operation_start_date := calculate_operation_start_date(NEW.purchase_date);
    END IF;
    
    RETURN NEW;
END;
$$;

-- トリガーを作成（既存のトリガーがある場合は削除してから作成）
DROP TRIGGER IF EXISTS trigger_set_operation_start_date ON user_nfts;
CREATE TRIGGER trigger_set_operation_start_date
    BEFORE INSERT OR UPDATE ON user_nfts
    FOR EACH ROW
    EXECUTE FUNCTION set_operation_start_date();

-- テスト用の計算例
DO $$
DECLARE
    test_date DATE;
    result_date DATE;
BEGIN
    RAISE NOTICE '=== NFT運用開始日計算テスト ===';
    
    -- 2025/01/06（月曜日）のテスト - 1/20から運用開始
    test_date := '2025-01-06';
    result_date := calculate_operation_start_date(test_date);
    RAISE NOTICE '購入日: % (月) → 運用開始日: % (期待値: 2025-01-20)', test_date, result_date;
    
    -- 2025/01/27（月曜日）のテスト - 2/10から運用開始
    test_date := '2025-01-27';
    result_date := calculate_operation_start_date(test_date);
    RAISE NOTICE '購入日: % (月) → 運用開始日: % (期待値: 2025-02-10)', test_date, result_date;
    
    -- 2025/01/28（火曜日）のテスト
    test_date := '2025-01-28';
    result_date := calculate_operation_start_date(test_date);
    RAISE NOTICE '購入日: % (火) → 運用開始日: %', test_date, result_date;
    
    -- 2025/01/29（水曜日）のテスト
    test_date := '2025-01-29';
    result_date := calculate_operation_start_date(test_date);
    RAISE NOTICE '購入日: % (水) → 運用開始日: %', test_date, result_date;
    
    -- 2025/01/30（木曜日）のテスト
    test_date := '2025-01-30';
    result_date := calculate_operation_start_date(test_date);
    RAISE NOTICE '購入日: % (木) → 運用開始日: %', test_date, result_date;
    
    -- 2025/01/31（金曜日）のテスト
    test_date := '2025-01-31';
    result_date := calculate_operation_start_date(test_date);
    RAISE NOTICE '購入日: % (金) → 運用開始日: %', test_date, result_date;
    
    -- 2025/02/01（土曜日）のテスト
    test_date := '2025-02-01';
    result_date := calculate_operation_start_date(test_date);
    RAISE NOTICE '購入日: % (土) → 運用開始日: %', test_date, result_date;
    
    -- 2025/02/02（日曜日）のテスト
    test_date := '2025-02-02';
    result_date := calculate_operation_start_date(test_date);
    RAISE NOTICE '購入日: % (日) → 運用開始日: %', test_date, result_date;
END;
$$;