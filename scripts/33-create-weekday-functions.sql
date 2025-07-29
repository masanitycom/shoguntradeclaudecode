-- 日本の祝日を考慮した平日判定関数

-- 平日判定関数（祝日除く）
CREATE OR REPLACE FUNCTION is_business_day(check_date DATE)
RETURNS BOOLEAN AS $$
BEGIN
    -- 土日チェック
    IF EXTRACT(DOW FROM check_date) IN (0, 6) THEN  -- 0=日曜, 6=土曜
        RETURN FALSE;
    END IF;
    
    -- 祝日チェック
    IF EXISTS (SELECT 1 FROM holidays_jp WHERE holiday_date = check_date) THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 週の営業日数を取得する関数
CREATE OR REPLACE FUNCTION get_business_days_in_week(week_start DATE)
RETURNS INTEGER AS $$
DECLARE
    business_days INTEGER := 0;
    current_date DATE;
    i INTEGER;
BEGIN
    -- 月曜日から金曜日まで（5日間）をチェック
    FOR i IN 0..4 LOOP
        current_date := week_start + i;
        IF is_business_day(current_date) THEN
            business_days := business_days + 1;
        END IF;
    END LOOP;
    
    RETURN business_days;
END;
$$ LANGUAGE plpgsql;

-- 日利計算用の営業日配分関数
CREATE OR REPLACE FUNCTION distribute_weekly_rate(
    weekly_rate DECIMAL(5,4),
    week_start DATE
) RETURNS TABLE(
    business_date DATE,
    daily_rate DECIMAL(5,4)
) AS $$
DECLARE
    business_days INTEGER;
    base_daily_rate DECIMAL(5,4);
    remaining_rate DECIMAL(5,4);
    current_date DATE;
    i INTEGER;
    days_processed INTEGER := 0;
BEGIN
    -- その週の営業日数を取得
    business_days := get_business_days_in_week(week_start);
    
    IF business_days = 0 THEN
        RETURN;  -- 営業日がない場合は何も返さない
    END IF;
    
    -- 基本日利を計算
    base_daily_rate := weekly_rate / business_days;
    remaining_rate := weekly_rate;
    
    -- 月曜日から金曜日まで配分
    FOR i IN 0..4 LOOP
        current_date := week_start + i;
        
        IF is_business_day(current_date) THEN
            days_processed := days_processed + 1;
            
            -- 最後の営業日は残りの率を全て割り当て（端数調整）
            IF days_processed = business_days THEN
                business_date := current_date;
                daily_rate := remaining_rate;
                remaining_rate := 0;
            ELSE
                business_date := current_date;
                daily_rate := base_daily_rate;
                remaining_rate := remaining_rate - base_daily_rate;
            END IF;
            
            RETURN NEXT;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 週の開始日（月曜日）を取得する関数
CREATE OR REPLACE FUNCTION get_week_start(input_date DATE DEFAULT CURRENT_DATE)
RETURNS DATE AS $$
BEGIN
    -- 入力日の週の月曜日を返す
    RETURN input_date - EXTRACT(DOW FROM input_date)::INTEGER + 1;
END;
$$ LANGUAGE plpgsql;

-- 日利計算関数（NFTの日利上限を考慮）
CREATE OR REPLACE FUNCTION calculate_daily_reward(
    user_nft_id UUID,
    target_date DATE,
    weekly_rate DECIMAL(5,4)
) RETURNS DECIMAL(10,2) AS $$
DECLARE
    nft_info RECORD;
    week_start DATE;
    daily_rate DECIMAL(5,4);
    calculated_reward DECIMAL(10,2);
BEGIN
    -- user_nftsとnftsの情報を取得
    SELECT 
        un.current_investment,
        un.total_earned,
        un.max_earning,
        un.is_active,
        n.daily_rate_limit
    INTO nft_info
    FROM user_nfts un
    JOIN nfts n ON un.nft_id = n.id
    WHERE un.id = user_nft_id;
    
    -- NFTが見つからない、または非アクティブの場合
    IF nft_info IS NULL OR NOT nft_info.is_active THEN
        RETURN 0;
    END IF;
    
    -- 既に300%に達している場合
    IF nft_info.total_earned >= nft_info.max_earning THEN
        RETURN 0;
    END IF;
    
    -- 営業日でない場合
    IF NOT is_business_day(target_date) THEN
        RETURN 0;
    END IF;
    
    -- その週の開始日を取得
    week_start := get_week_start(target_date);
    
    -- その日の日利を取得
    SELECT dr.daily_rate INTO daily_rate
    FROM distribute_weekly_rate(weekly_rate, week_start) dr
    WHERE dr.business_date = target_date;
    
    -- 日利が取得できない場合
    IF daily_rate IS NULL THEN
        RETURN 0;
    END IF;
    
    -- NFTの日利上限を適用
    IF daily_rate > nft_info.daily_rate_limit THEN
        daily_rate := nft_info.daily_rate_limit;
    END IF;
    
    -- 報酬額を計算
    calculated_reward := nft_info.current_investment * daily_rate;
    
    -- 300%キャップを超えないように調整
    IF nft_info.total_earned + calculated_reward > nft_info.max_earning THEN
        calculated_reward := nft_info.max_earning - nft_info.total_earned;
    END IF;
    
    -- 負の値の場合は0
    IF calculated_reward < 0 THEN
        calculated_reward := 0;
    END IF;
    
    RETURN calculated_reward;
END;
$$ LANGUAGE plpgsql;

-- テスト用：今週の営業日配分を確認
DO $$
DECLARE
    test_week_start DATE := get_week_start(CURRENT_DATE);
    result RECORD;
BEGIN
    RAISE NOTICE '=== 今週の営業日配分テスト（週利2.6%%） ===';
    RAISE NOTICE '週開始日: %', test_week_start;
    RAISE NOTICE '今日: % (営業日: %)', CURRENT_DATE, is_business_day(CURRENT_DATE);
    
    FOR result IN 
        SELECT * FROM distribute_weekly_rate(0.026, test_week_start)
    LOOP
        RAISE NOTICE '% (%) : %.4f%%', 
            result.business_date,
            to_char(result.business_date, 'Dy'),
            result.daily_rate * 100;
    END LOOP;
    
    RAISE NOTICE '営業日数: %', get_business_days_in_week(test_week_start);
END
$$;

-- 完了メッセージ
SELECT '平日判定・日利配分関数の作成が完了しました' AS result;
