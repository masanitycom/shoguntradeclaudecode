-- 週利配分テストシステム（正確な合計保証）

-- 1. 正確な週利配分関数を作成
DROP FUNCTION IF EXISTS generate_exact_weekly_distribution(numeric, numeric);

CREATE OR REPLACE FUNCTION generate_exact_weekly_distribution(
    weekly_rate NUMERIC,
    daily_limit NUMERIC
)
RETURNS TABLE(
    monday_rate NUMERIC,
    tuesday_rate NUMERIC,
    wednesday_rate NUMERIC,
    thursday_rate NUMERIC,
    friday_rate NUMERIC,
    total_rate NUMERIC,
    is_valid BOOLEAN
) AS $$
DECLARE
    rates NUMERIC[] := ARRAY[0, 0, 0, 0, 0];
    remaining_rate NUMERIC := weekly_rate;
    max_possible_rate NUMERIC := daily_limit * 5;
    zero_days INTEGER;
    active_days INTEGER;
    i INTEGER;
    attempts INTEGER := 0;
    rate_per_day NUMERIC;
    final_adjustment NUMERIC;
BEGIN
    -- 週利が理論上限を超える場合はエラー
    IF weekly_rate > max_possible_rate THEN
        RETURN QUERY SELECT 0::NUMERIC, 0::NUMERIC, 0::NUMERIC, 0::NUMERIC, 0::NUMERIC, 0::NUMERIC, false;
        RETURN;
    END IF;
    
    -- 完全配分が可能な場合の処理
    WHILE attempts < 100 AND remaining_rate > 0.0001 LOOP
        attempts := attempts + 1;
        rates := ARRAY[0, 0, 0, 0, 0];
        remaining_rate := weekly_rate;
        
        -- ランダムに0-2日を0%にする
        zero_days := floor(random() * 3)::INTEGER;
        
        -- 必要最小日数を計算
        IF weekly_rate > daily_limit * (5 - zero_days) THEN
            zero_days := 5 - ceil(weekly_rate / daily_limit)::INTEGER;
        END IF;
        
        -- 0%の日をランダムに選択
        FOR i IN 1..zero_days LOOP
            LOOP
                DECLARE
                    day_index INTEGER := floor(random() * 5)::INTEGER + 1;
                BEGIN
                    IF rates[day_index] = 0 THEN
                        -- この日は0%のまま
                        EXIT;
                    END IF;
                END;
            END LOOP;
        END LOOP;
        
        active_days := 5 - zero_days;
        
        -- アクティブな日に配分
        FOR i IN 1..5 LOOP
            IF rates[i] = 0 AND remaining_rate > 0 THEN
                IF active_days = 1 THEN
                    -- 最後のアクティブ日：残り全部（上限チェック）
                    IF remaining_rate <= daily_limit THEN
                        rates[i] := remaining_rate;
                        remaining_rate := 0;
                    ELSE
                        -- 上限を超える場合は調整が必要
                        CONTINUE;
                    END IF;
                ELSE
                    -- ランダム配分（残りの20%-80%、ただし上限以下）
                    rate_per_day := LEAST(
                        remaining_rate * (0.2 + random() * 0.6),
                        daily_limit
                    );
                    rates[i] := rate_per_day;
                    remaining_rate := remaining_rate - rate_per_day;
                    active_days := active_days - 1;
                END IF;
            END IF;
        END LOOP;
        
        -- 残りがある場合は最初のアクティブ日に追加
        IF remaining_rate > 0.0001 THEN
            FOR i IN 1..5 LOOP
                IF rates[i] > 0 THEN
                    final_adjustment := LEAST(remaining_rate, daily_limit - rates[i]);
                    rates[i] := rates[i] + final_adjustment;
                    remaining_rate := remaining_rate - final_adjustment;
                    IF remaining_rate <= 0.0001 THEN
                        EXIT;
                    END IF;
                END IF;
            END LOOP;
        END IF;
        
        -- 成功判定
        IF remaining_rate <= 0.0001 THEN
            EXIT;
        END IF;
    END LOOP;
    
    -- 結果を返す
    RETURN QUERY SELECT 
        rates[1], 
        rates[2], 
        rates[3], 
        rates[4], 
        rates[5],
        rates[1] + rates[2] + rates[3] + rates[4] + rates[5],
        (remaining_rate <= 0.0001);
END;
$$ LANGUAGE plpgsql;

-- 2. 週利1.8%のテスト（SHOGUN NFT 100の上限0.5%）
DO $$
DECLARE
    test_record RECORD;
    test_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== 週利1.8%配分テスト（日利上限0.5%）===';
    
    FOR test_count IN 1..10 LOOP
        SELECT * INTO test_record 
        FROM generate_exact_weekly_distribution(0.018, 0.005);
        
        RAISE NOTICE 'テスト%: 月%.2f%% 火%.2f%% 水%.2f%% 木%.2f%% 金%.2f%% = 合計%.2f%% (有効: %)',
            test_count,
            test_record.monday_rate * 100,
            test_record.tuesday_rate * 100,
            test_record.wednesday_rate * 100,
            test_record.thursday_rate * 100,
            test_record.friday_rate * 100,
            test_record.total_rate * 100,
            test_record.is_valid;
    END LOOP;
END $$;

-- 3. 異なる週利での配分テスト
DO $$
DECLARE
    test_record RECORD;
    weekly_rates NUMERIC[] := ARRAY[0.010, 0.015, 0.018, 0.020, 0.025];
    rate NUMERIC;
BEGIN
    RAISE NOTICE '=== 異なる週利での配分テスト ===';
    
    FOREACH rate IN ARRAY weekly_rates LOOP
        SELECT * INTO test_record 
        FROM generate_exact_weekly_distribution(rate, 0.005);
        
        RAISE NOTICE '週利%.1f%%: 月%.2f%% 火%.2f%% 水%.2f%% 木%.2f%% 金%.2f%% = 合計%.2f%% (有効: %)',
            rate * 100,
            test_record.monday_rate * 100,
            test_record.tuesday_rate * 100,
            test_record.wednesday_rate * 100,
            test_record.thursday_rate * 100,
            test_record.friday_rate * 100,
            test_record.total_rate * 100,
            test_record.is_valid;
    END LOOP;
END $$;

-- 4. OHTAKIYO投資額$100での収益計算例
DO $$
DECLARE
    test_record RECORD;
    investment_amount NUMERIC := 100;
BEGIN
    RAISE NOTICE '=== OHTAKIYO収益計算例（投資額$100）===';
    
    SELECT * INTO test_record 
    FROM generate_exact_weekly_distribution(0.018, 0.005);
    
    RAISE NOTICE '週利1.8%%配分:';
    RAISE NOTICE '月曜: %.2f%% → $%.2f', test_record.monday_rate * 100, investment_amount * test_record.monday_rate;
    RAISE NOTICE '火曜: %.2f%% → $%.2f', test_record.tuesday_rate * 100, investment_amount * test_record.tuesday_rate;
    RAISE NOTICE '水曜: %.2f%% → $%.2f', test_record.wednesday_rate * 100, investment_amount * test_record.wednesday_rate;
    RAISE NOTICE '木曜: %.2f%% → $%.2f', test_record.thursday_rate * 100, investment_amount * test_record.thursday_rate;
    RAISE NOTICE '金曜: %.2f%% → $%.2f', test_record.friday_rate * 100, investment_amount * test_record.friday_rate;
    RAISE NOTICE '週合計: %.2f%% → $%.2f', test_record.total_rate * 100, investment_amount * test_record.total_rate;
END $$;

-- 5. 上限を超える週利のテスト（週利3.0%）
DO $$
DECLARE
    test_record RECORD;
BEGIN
    RAISE NOTICE '=== 上限超過テスト（週利3.0%、上限2.5%）===';
    
    SELECT * INTO test_record 
    FROM generate_exact_weekly_distribution(0.030, 0.005);
    
    IF test_record.is_valid THEN
        RAISE NOTICE '週利3.0%%: 月%.2f%% 火%.2f%% 水%.2f%% 木%.2f%% 金%.2f%% = 合計%.2f%%',
            test_record.monday_rate * 100,
            test_record.tuesday_rate * 100,
            test_record.wednesday_rate * 100,
            test_record.thursday_rate * 100,
            test_record.friday_rate * 100,
            test_record.total_rate * 100;
    ELSE
        RAISE NOTICE '週利3.0%%は上限2.5%%を超えるため配分不可能';
    END IF;
END $$;

RAISE NOTICE '正確な週利配分システムのテストが完了しました';
