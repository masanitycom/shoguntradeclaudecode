-- 1. 週利設定テーブルを作成
CREATE TABLE IF NOT EXISTS weekly_rates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    week_start_date DATE NOT NULL,
    week_end_date DATE NOT NULL,
    weekly_rate NUMERIC(5,3) NOT NULL, -- 例: 3.600 (3.6%)
    monday_rate NUMERIC(5,3) DEFAULT 0,
    tuesday_rate NUMERIC(5,3) DEFAULT 0,
    wednesday_rate NUMERIC(5,3) DEFAULT 0,
    thursday_rate NUMERIC(5,3) DEFAULT 0,
    friday_rate NUMERIC(5,3) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

-- 2. インデックス作成
CREATE INDEX IF NOT EXISTS idx_weekly_rates_week_start ON weekly_rates(week_start_date);
CREATE INDEX IF NOT EXISTS idx_weekly_rates_week_end ON weekly_rates(week_end_date);

-- 3. 週利を日利に自動振り分けする関数
CREATE OR REPLACE FUNCTION distribute_weekly_rate(
    p_weekly_rate NUMERIC,
    p_week_start_date DATE
) RETURNS TABLE(
    day_name TEXT,
    day_date DATE,
    rate NUMERIC
) AS $$
DECLARE
    remaining_rate NUMERIC := p_weekly_rate;
    rates NUMERIC[] := ARRAY[0, 0, 0, 0, 0]; -- 月火水木金
    i INTEGER;
    random_rate NUMERIC;
    min_rate NUMERIC := 0.1; -- 最小0.1%
    max_single_rate NUMERIC;
BEGIN
    -- 最大単日利率を週利の60%に設定
    max_single_rate := p_weekly_rate * 0.6;
    
    -- ランダムに5日間に振り分け（0%の日もあり）
    FOR i IN 1..5 LOOP
        IF i = 5 THEN
            -- 最後の日は残り全部
            rates[i] := remaining_rate;
        ELSE
            -- ランダムに0%から残り利率の70%まで
            IF remaining_rate > 0 THEN
                random_rate := ROUND((random() * LEAST(remaining_rate * 0.7, max_single_rate))::NUMERIC, 3);
                -- 10%の確率で0%にする
                IF random() < 0.1 THEN
                    random_rate := 0;
                END IF;
                rates[i] := random_rate;
                remaining_rate := remaining_rate - random_rate;
            ELSE
                rates[i] := 0;
            END IF;
        END IF;
    END LOOP;
    
    -- 結果を返す
    RETURN QUERY
    SELECT '月曜日'::TEXT, p_week_start_date, rates[1]
    UNION ALL
    SELECT '火曜日'::TEXT, p_week_start_date + 1, rates[2]
    UNION ALL
    SELECT '水曜日'::TEXT, p_week_start_date + 2, rates[3]
    UNION ALL
    SELECT '木曜日'::TEXT, p_week_start_date + 3, rates[4]
    UNION ALL
    SELECT '金曜日'::TEXT, p_week_start_date + 4, rates[5];
END;
$$ LANGUAGE plpgsql;

-- 4. 週利設定と日利振り分けを行う関数
CREATE OR REPLACE FUNCTION set_weekly_rate(
    p_weekly_rate NUMERIC,
    p_week_start_date DATE,
    p_admin_user_id UUID
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    distribution JSONB
) AS $$
DECLARE
    week_end_date DATE;
    distribution_result JSONB := '[]'::JSONB;
    day_record RECORD;
    new_weekly_rate_id UUID;
BEGIN
    -- 週末日を計算
    week_end_date := p_week_start_date + 4; -- 金曜日
    
    -- 既存の同じ週のデータを削除
    DELETE FROM weekly_rates WHERE week_start_date = p_week_start_date;
    
    -- 日利振り分けを実行
    FOR day_record IN 
        SELECT * FROM distribute_weekly_rate(p_weekly_rate, p_week_start_date)
    LOOP
        distribution_result := distribution_result || jsonb_build_object(
            'day_name', day_record.day_name,
            'day_date', day_record.day_date,
            'rate', day_record.rate
        );
    END LOOP;
    
    -- 週利設定を保存
    INSERT INTO weekly_rates (
        week_start_date,
        week_end_date,
        weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        created_by
    ) VALUES (
        p_week_start_date,
        week_end_date,
        p_weekly_rate,
        (distribution_result->0->>'rate')::NUMERIC,
        (distribution_result->1->>'rate')::NUMERIC,
        (distribution_result->2->>'rate')::NUMERIC,
        (distribution_result->3->>'rate')::NUMERIC,
        (distribution_result->4->>'rate')::NUMERIC,
        p_admin_user_id
    ) RETURNING id INTO new_weekly_rate_id;
    
    RETURN QUERY SELECT 
        true,
        '週利設定が完了しました'::TEXT,
        distribution_result;
END;
$$ LANGUAGE plpgsql;

-- 5. ユーザー向け日利履歴取得関数
CREATE OR REPLACE FUNCTION get_daily_rate_history(
    p_user_id UUID DEFAULT NULL
) RETURNS TABLE(
    date DATE,
    day_name TEXT,
    rate NUMERIC,
    week_start_date DATE,
    weekly_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        wr.week_start_date as date,
        '月曜日'::TEXT as day_name,
        wr.monday_rate as rate,
        wr.week_start_date,
        wr.weekly_rate
    FROM weekly_rates wr
    WHERE wr.monday_rate > 0
    
    UNION ALL
    
    SELECT 
        wr.week_start_date + 1 as date,
        '火曜日'::TEXT as day_name,
        wr.tuesday_rate as rate,
        wr.week_start_date,
        wr.weekly_rate
    FROM weekly_rates wr
    WHERE wr.tuesday_rate > 0
    
    UNION ALL
    
    SELECT 
        wr.week_start_date + 2 as date,
        '水曜日'::TEXT as day_name,
        wr.wednesday_rate as rate,
        wr.week_start_date,
        wr.weekly_rate
    FROM weekly_rates wr
    WHERE wr.wednesday_rate > 0
    
    UNION ALL
    
    SELECT 
        wr.week_start_date + 3 as date,
        '木曜日'::TEXT as day_name,
        wr.thursday_rate as rate,
        wr.week_start_date,
        wr.weekly_rate
    FROM weekly_rates wr
    WHERE wr.thursday_rate > 0
    
    UNION ALL
    
    SELECT 
        wr.week_start_date + 4 as date,
        '金曜日'::TEXT as day_name,
        wr.friday_rate as rate,
        wr.week_start_date,
        wr.weekly_rate
    FROM weekly_rates wr
    WHERE wr.friday_rate > 0
    
    ORDER BY date DESC;
END;
$$ LANGUAGE plpgsql;

-- 6. テストデータ
SELECT set_weekly_rate(3.6, '2025-06-23', (SELECT id FROM users WHERE user_id = 'admin001' LIMIT 1));
