-- 🚀 外部計算用テーブルとビュー作成

-- 計算用データエクスポートビュー
CREATE OR REPLACE VIEW calculation_data_export AS
SELECT 
    u.id as user_id,
    un.id as user_nft_id,
    un.purchase_price,
    n.daily_rate_limit,
    n.name as nft_name,
    drg.group_name,
    u.created_at as user_created_at,
    un.created_at as nft_purchased_at
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
LEFT JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
WHERE un.purchase_price > 0 
AND n.daily_rate_limit > 0;

-- 外部計算結果テーブル
CREATE TABLE IF NOT EXISTS external_calculation_results (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    user_nft_id INTEGER REFERENCES user_nfts(id),
    reward_amount NUMERIC(10,2) NOT NULL,
    calculation_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_nft_id, calculation_date)
);

-- インデックス作成
CREATE INDEX IF NOT EXISTS idx_external_calc_date ON external_calculation_results(calculation_date);
CREATE INDEX IF NOT EXISTS idx_external_calc_user ON external_calculation_results(user_id);

-- 簡単な関数群を再作成
CREATE OR REPLACE FUNCTION get_system_status_simple()
RETURNS TABLE(
    total_users BIGINT,
    active_nfts BIGINT,
    pending_rewards NUMERIC,
    last_calculation TEXT,
    current_week_rates BIGINT,
    total_backups BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM users)::BIGINT,
        (SELECT COUNT(*) FROM user_nfts)::BIGINT,
        (SELECT COALESCE(SUM(reward_amount), 0) FROM daily_rewards WHERE reward_date >= CURRENT_DATE - INTERVAL '7 days')::NUMERIC,
        (SELECT COALESCE(MAX(created_at)::TEXT, '未実行') FROM daily_rewards)::TEXT,
        (SELECT COUNT(DISTINCT week_start_date) FROM group_weekly_rates)::BIGINT,
        0::BIGINT -- バックアップ機能は後で実装
    ;
END;
$$ LANGUAGE plpgsql;

-- 週利設定取得関数
CREATE OR REPLACE FUNCTION get_weekly_rates_simple()
RETURNS TABLE(
    id UUID,
    week_start_date DATE,
    week_end_date DATE,
    weekly_rate NUMERIC,
    monday_rate NUMERIC,
    tuesday_rate NUMERIC,
    wednesday_rate NUMERIC,
    thursday_rate NUMERIC,
    friday_rate NUMERIC,
    group_name TEXT,
    distribution_method TEXT,
    has_backup BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwr.id,
        gwr.week_start_date,
        gwr.week_end_date,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        COALESCE(drg.group_name, 'Unknown')::TEXT,
        gwr.distribution_method,
        false as has_backup -- 簡略化
    FROM group_weekly_rates gwr
    LEFT JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit;
END;
$$ LANGUAGE plpgsql;

-- 簡単な週利設定関数
CREATE OR REPLACE FUNCTION set_group_weekly_rate_simple(
    p_week_start_date DATE,
    p_group_name TEXT,
    p_weekly_rate NUMERIC
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    week_end_date DATE;
    group_id UUID;
    rates NUMERIC[] := ARRAY[0, 0, 0, 0, 0];
    remaining_rate NUMERIC;
    random_rate NUMERIC;
    i INTEGER;
BEGIN
    week_end_date := p_week_start_date + 4;
    
    -- グループID取得
    SELECT id INTO group_id FROM daily_rate_groups WHERE group_name = p_group_name;
    
    IF group_id IS NULL THEN
        RETURN QUERY SELECT false, format('グループ "%s" が見つかりません', p_group_name);
        RETURN;
    END IF;
    
    -- 既存データ削除
    DELETE FROM group_weekly_rates 
    WHERE week_start_date = p_week_start_date AND group_id = set_group_weekly_rate_simple.group_id;
    
    -- ランダム分配計算
    remaining_rate := p_weekly_rate / 100.0;
    
    FOR i IN 1..5 LOOP
        IF i = 5 THEN
            rates[i] := remaining_rate;
        ELSE
            IF remaining_rate > 0 THEN
                random_rate := ROUND((random() * remaining_rate * 0.7)::NUMERIC, 4);
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
    
    -- データ挿入
    INSERT INTO group_weekly_rates (
        group_id,
        week_start_date,
        week_end_date,
        weekly_rate,
        monday_rate,
        tuesday_rate,
        wednesday_rate,
        thursday_rate,
        friday_rate,
        distribution_method
    ) VALUES (
        set_group_weekly_rate_simple.group_id,
        p_week_start_date,
        week_end_date,
        p_weekly_rate / 100.0,
        rates[1],
        rates[2],
        rates[3],
        rates[4],
        rates[5],
        'random'
    );
    
    RETURN QUERY SELECT true, format('%s: %s%%設定完了', p_group_name, p_weekly_rate);
END;
$$ LANGUAGE plpgsql;

-- 強制日利計算関数（簡易版）
CREATE OR REPLACE FUNCTION force_daily_calculation_simple()
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    calculation_date DATE,
    processed_count INTEGER
) AS $$
DECLARE
    today_date DATE := CURRENT_DATE;
    processed_count INTEGER := 0;
BEGIN
    -- 簡易計算（外部計算システムに移行予定）
    INSERT INTO daily_rewards (
        user_nft_id,
        reward_amount,
        reward_date,
        created_at
    )
    SELECT 
        un.id,
        LEAST(un.purchase_price * 0.01, n.daily_rate_limit) as reward_amount,
        today_date,
        NOW()
    FROM user_nfts un
    JOIN nfts n ON un.nft_id = n.id
    WHERE un.purchase_price > 0
    AND n.daily_rate_limit > 0
    AND EXTRACT(DOW FROM today_date) BETWEEN 1 AND 5 -- 平日のみ
    ON CONFLICT (user_nft_id, reward_date) DO UPDATE SET
        reward_amount = EXCLUDED.reward_amount,
        updated_at = NOW();
    
    GET DIAGNOSTICS processed_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        true,
        format('簡易計算完了: %s件処理', processed_count),
        today_date,
        processed_count;
END;
$$ LANGUAGE plpgsql;
