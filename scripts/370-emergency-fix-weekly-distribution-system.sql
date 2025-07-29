-- =====================================================================
-- 緊急修正：週利配分システムの根本的な問題を修正
-- =====================================================================

-- 1. まず現在の問題状況を確認
SELECT 
    '🚨 現在の問題確認' as status,
    n.name,
    n.price,
    n.daily_rate_limit as nft_daily_limit,
    ROUND(n.daily_rate_limit * 100, 2) || '%' as nft_limit_percent,
    drg.group_name,
    gwr.weekly_rate,
    ROUND(gwr.weekly_rate * 100, 2) || '%' as weekly_rate_percent,
    gwr.monday_rate + gwr.tuesday_rate + gwr.wednesday_rate + gwr.thursday_rate + gwr.friday_rate as actual_total,
    ROUND((gwr.monday_rate + gwr.tuesday_rate + gwr.wednesday_rate + gwr.thursday_rate + gwr.friday_rate) * 100, 2) || '%' as actual_total_percent,
    CASE 
        WHEN gwr.monday_rate > n.daily_rate_limit THEN '月曜超過'
        WHEN gwr.tuesday_rate > n.daily_rate_limit THEN '火曜超過'
        WHEN gwr.wednesday_rate > n.daily_rate_limit THEN '水曜超過'
        WHEN gwr.thursday_rate > n.daily_rate_limit THEN '木曜超過'
        WHEN gwr.friday_rate > n.daily_rate_limit THEN '金曜超過'
        ELSE 'OK'
    END as limit_check
FROM nfts n
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
LEFT JOIN group_weekly_rates gwr ON drg.id = gwr.group_id 
    AND gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)::date
WHERE n.name LIKE '%100%'
ORDER BY n.price;

-- 2. SHOGUN NFT 100の正しい情報を確認・修正
UPDATE nfts 
SET daily_rate_limit = 0.005  -- 0.5%
WHERE name = 'SHOGUN NFT 100' AND daily_rate_limit != 0.005;

-- 確認
SELECT 
    '✅ SHOGUN NFT 100 修正確認' as status,
    name,
    price,
    daily_rate_limit,
    ROUND(daily_rate_limit * 100, 2) || '%' as daily_limit_percent
FROM nfts 
WHERE name = 'SHOGUN NFT 100';

-- 3. 正しい週利配分関数を作成（NFT上限を考慮）
DROP FUNCTION IF EXISTS create_smart_weekly_distribution(numeric, numeric);

CREATE OR REPLACE FUNCTION create_smart_weekly_distribution(
    target_weekly_rate NUMERIC,
    nft_daily_limit NUMERIC
)
RETURNS TABLE(
    monday_rate NUMERIC,
    tuesday_rate NUMERIC,
    wednesday_rate NUMERIC,
    thursday_rate NUMERIC,
    friday_rate NUMERIC,
    actual_weekly_total NUMERIC,
    distribution_note TEXT
) AS $$
DECLARE
    max_daily_rate NUMERIC := nft_daily_limit;  -- NFTの日利上限
    max_possible_weekly NUMERIC := max_daily_rate * 5;  -- 理論上の最大週利
    adjusted_weekly_rate NUMERIC;
    remaining_rate NUMERIC;
    rates NUMERIC[] := ARRAY[0, 0, 0, 0, 0];
    zero_days INTEGER;
    active_days INTEGER;
    i INTEGER;
    day_index INTEGER;
    base_rate NUMERIC;
    note TEXT := '';
BEGIN
    -- 週利が理論上限を超える場合は調整
    IF target_weekly_rate > max_possible_weekly THEN
        adjusted_weekly_rate := max_possible_weekly;
        note := format('週利を%s%%から%s%%に調整（NFT上限による制限）', 
                      ROUND(target_weekly_rate * 100, 2), 
                      ROUND(adjusted_weekly_rate * 100, 2));
    ELSE
        adjusted_weekly_rate := target_weekly_rate;
        note := '設定通りの週利で配分';
    END IF;
    
    remaining_rate := adjusted_weekly_rate;
    
    -- ランダムに0-2日を0%にする（0%がない週もある）
    zero_days := floor(random() * 3)::INTEGER; -- 0, 1, 2日
    active_days := 5 - zero_days;
    
    -- 全部0%の場合は1日だけ活動させる
    IF active_days = 0 THEN
        active_days := 1;
        zero_days := 4;
    END IF;
    
    -- ランダムに0%の日を選択
    FOR i IN 1..zero_days LOOP
        LOOP
            day_index := floor(random() * 5)::INTEGER + 1;
            EXIT WHEN rates[day_index] = 0; -- まだ0%に設定されていない日
        END LOOP;
        -- この日は0%のまま（既に0で初期化済み）
    END LOOP;
    
    -- 残りの日に配分（NFT上限を超えないように）
    FOR i IN 1..5 LOOP
        IF rates[i] = 0 AND remaining_rate > 0 THEN
            -- この日が活動日の場合
            IF active_days = 1 THEN
                -- 最後の活動日なら残り全部（ただし上限チェック）
                rates[i] := LEAST(remaining_rate, max_daily_rate);
                remaining_rate := remaining_rate - rates[i];
            ELSE
                -- ランダムに配分（残りの20%-80%、ただし上限チェック）
                base_rate := remaining_rate * (0.2 + random() * 0.6);
                rates[i] := LEAST(base_rate, max_daily_rate);
                remaining_rate := remaining_rate - rates[i];
                active_days := active_days - 1;
            END IF;
        END IF;
    END LOOP;
    
    -- 端数が残った場合の処理
    IF remaining_rate > 0.0001 THEN
        -- まだ上限に達していない日に追加配分
        FOR i IN 1..5 LOOP
            IF rates[i] > 0 AND rates[i] < max_daily_rate THEN
                DECLARE
                    additional NUMERIC := LEAST(remaining_rate, max_daily_rate - rates[i]);
                BEGIN
                    rates[i] := rates[i] + additional;
                    remaining_rate := remaining_rate - additional;
                    EXIT WHEN remaining_rate <= 0.0001;
                END;
            END IF;
        END LOOP;
    END IF;
    
    -- 結果を返す
    RETURN QUERY SELECT 
        rates[1], rates[2], rates[3], rates[4], rates[5],
        rates[1] + rates[2] + rates[3] + rates[4] + rates[5],
        note;
END;
$$ LANGUAGE plpgsql;

-- 4. 全グループの週利を正しく再設定する関数
CREATE OR REPLACE FUNCTION fix_all_weekly_distributions(
    target_week_start DATE,
    default_weekly_rate NUMERIC DEFAULT 0.026
)
RETURNS VOID AS $$
DECLARE
    group_record RECORD;
    distribution RECORD;
BEGIN
    -- 既存の週利データを削除
    DELETE FROM group_weekly_rates WHERE week_start_date = target_week_start;
    
    -- 各グループに対して正しい配分を適用
    FOR group_record IN
        SELECT 
            drg.id,
            drg.group_name,
            drg.daily_rate_limit,
            ROUND(drg.daily_rate_limit * 100, 2) as limit_percent
        FROM daily_rate_groups drg 
        ORDER BY drg.daily_rate_limit
    LOOP
        -- NFT上限を考慮した配分を生成
        SELECT * INTO distribution 
        FROM create_smart_weekly_distribution(default_weekly_rate, group_record.daily_rate_limit);
        
        -- 週利データを挿入
        INSERT INTO group_weekly_rates (
            group_id,
            week_start_date,
            week_end_date,
            week_number,
            weekly_rate,
            monday_rate,
            tuesday_rate,
            wednesday_rate,
            thursday_rate,
            friday_rate,
            distribution_method
        ) VALUES (
            group_record.id,
            target_week_start,
            target_week_start + 4,
            EXTRACT(week FROM target_week_start),
            distribution.actual_weekly_total,  -- 実際の週利合計
            distribution.monday_rate,
            distribution.tuesday_rate,
            distribution.wednesday_rate,
            distribution.thursday_rate,
            distribution.friday_rate,
            'smart_auto'
        );
        
        RAISE NOTICE '✅ %（上限%）: 設定週利%% → 実際週利%%', 
            group_record.group_name,
            group_record.limit_percent,
            ROUND(default_weekly_rate * 100, 2),
            ROUND(distribution.actual_weekly_total * 100, 2);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 5. 今週の週利を正しく再設定
SELECT fix_all_weekly_distributions(DATE_TRUNC('week', CURRENT_DATE)::DATE, 0.026);

-- 6. 修正結果を確認
SELECT 
    '🎯 修正後の週利配分確認' as status,
    drg.group_name,
    ROUND(drg.daily_rate_limit * 100, 2) || '%' as nft_limit,
    ROUND(gwr.weekly_rate * 100, 2) || '%' as actual_weekly,
    CASE WHEN gwr.monday_rate = 0 THEN '0%' ELSE ROUND(gwr.monday_rate * 100, 2) || '%' END as mon,
    CASE WHEN gwr.tuesday_rate = 0 THEN '0%' ELSE ROUND(gwr.tuesday_rate * 100, 2) || '%' END as tue,
    CASE WHEN gwr.wednesday_rate = 0 THEN '0%' ELSE ROUND(gwr.wednesday_rate * 100, 2) || '%' END as wed,
    CASE WHEN gwr.thursday_rate = 0 THEN '0%' ELSE ROUND(gwr.thursday_rate * 100, 2) || '%' END as thu,
    CASE WHEN gwr.friday_rate = 0 THEN '0%' ELSE ROUND(gwr.friday_rate * 100, 2) || '%' END as fri,
    CASE 
        WHEN gwr.monday_rate > drg.daily_rate_limit OR
             gwr.tuesday_rate > drg.daily_rate_limit OR
             gwr.wednesday_rate > drg.daily_rate_limit OR
             gwr.thursday_rate > drg.daily_rate_limit OR
             gwr.friday_rate > drg.daily_rate_limit 
        THEN '❌ 上限超過'
        ELSE '✅ 正常'
    END as validation
FROM daily_rate_groups drg
JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
WHERE gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)::date
ORDER BY drg.daily_rate_limit;

-- 7. SHOGUN NFT 100の具体例を表示
SELECT 
    '💡 SHOGUN NFT 100 具体例' as status,
    'SHOGUN NFT 100' as nft_name,
    '$100' as investment,
    '0.5%' as daily_limit,
    CASE WHEN gwr.monday_rate = 0 THEN '月: $0 (0%)'
         ELSE format('月: $%s (%s%%)', 
                    ROUND(100 * gwr.monday_rate, 2), 
                    ROUND(gwr.monday_rate * 100, 2)) END as monday_example,
    CASE WHEN gwr.tuesday_rate = 0 THEN '火: $0 (0%)'
         ELSE format('火: $%s (%s%%)', 
                    ROUND(100 * gwr.tuesday_rate, 2), 
                    ROUND(gwr.tuesday_rate * 100, 2)) END as tuesday_example,
    CASE WHEN gwr.wednesday_rate = 0 THEN '水: $0 (0%)'
         ELSE format('水: $%s (%s%%)', 
                    ROUND(100 * gwr.wednesday_rate, 2), 
                    ROUND(gwr.wednesday_rate * 100, 2)) END as wednesday_example,
    format('週合計: $%s (%s%%)', 
           ROUND(100 * gwr.weekly_rate, 2), 
           ROUND(gwr.weekly_rate * 100, 2)) as weekly_total
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE drg.daily_rate_limit = 0.005  -- 0.5%グループ
  AND gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)::date;

-- 8. OHTAKIYOユーザーの正しい計算を再実行
SELECT 
    '🔄 OHTAKIYO 再計算準備' as status,
    'NFT上限を考慮した正しい週利配分が完了しました' as message,
    '次に日利計算を再実行してください' as next_step;
