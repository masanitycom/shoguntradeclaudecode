-- 緊急修復: 週利管理システムの完全復旧
-- 過去の週利設定、グループ別設定、履歴表示を全て復活

-- 1. 既存の競合する関数を削除
DROP FUNCTION IF EXISTS get_system_status();
DROP FUNCTION IF EXISTS get_weekly_rates_with_groups();
DROP FUNCTION IF EXISTS set_custom_weekly_rate(NUMERIC, TEXT);
DROP FUNCTION IF EXISTS force_daily_calculation();

-- 2. 週利データ取得関数を作成
CREATE OR REPLACE FUNCTION get_weekly_rates_with_groups()
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
    created_at TIMESTAMP WITH TIME ZONE
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
        drg.group_name,
        COALESCE(gwr.distribution_method, 'random') as distribution_method,
        gwr.created_at
    FROM group_weekly_rates gwr
    JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    ORDER BY gwr.week_start_date DESC, drg.group_name;
END;
$$ LANGUAGE plpgsql;

-- 3. システム状況取得関数を作成
CREATE OR REPLACE FUNCTION get_system_status()
RETURNS TABLE(
    total_users INTEGER,
    active_nfts INTEGER,
    pending_rewards NUMERIC,
    last_calculation TEXT,
    current_week_rates INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM users WHERE is_active = true),
        (SELECT COUNT(*)::INTEGER FROM user_nfts WHERE is_active = true),
        (SELECT COALESCE(SUM(reward_amount), 0) FROM daily_rewards WHERE is_claimed = false),
        (SELECT COALESCE(MAX(reward_date)::TEXT, '未実行') FROM daily_rewards),
        (SELECT COUNT(*)::INTEGER FROM group_weekly_rates WHERE week_start_date >= CURRENT_DATE - INTERVAL '7 days');
END;
$$ LANGUAGE plpgsql;

-- 4. 過去の週利設定機能を作成
CREATE OR REPLACE FUNCTION set_historical_weekly_rate(
    p_week_start_date DATE,
    p_weekly_rate NUMERIC,
    p_distribution_method TEXT DEFAULT 'random',
    p_admin_user_id UUID DEFAULT NULL
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    records_created INTEGER
) AS $$
DECLARE
    week_end_date DATE;
    group_record RECORD;
    rates NUMERIC[] := ARRAY[0, 0, 0, 0, 0]; -- 月火水木金
    remaining_rate NUMERIC;
    random_rate NUMERIC;
    i INTEGER;
    records_count INTEGER := 0;
BEGIN
    -- 週末日を計算
    week_end_date := p_week_start_date + 4; -- 金曜日
    
    -- 既存の同じ週のデータを削除
    DELETE FROM group_weekly_rates WHERE week_start_date = p_week_start_date;
    
    -- 各グループに対して週利を設定
    FOR group_record IN 
        SELECT id, group_name FROM daily_rate_groups ORDER BY daily_rate_limit
    LOOP
        remaining_rate := p_weekly_rate / 100; -- パーセントを小数に変換
        
        -- 分配方法に応じて日利を計算
        IF p_distribution_method = 'equal' THEN
            -- 均等分配
            FOR i IN 1..5 LOOP
                rates[i] := remaining_rate / 5;
            END LOOP;
        ELSE
            -- ランダム分配
            FOR i IN 1..5 LOOP
                IF i = 5 THEN
                    -- 最後の日は残り全部
                    rates[i] := remaining_rate;
                ELSE
                    -- ランダムに0%から残り利率の70%まで
                    IF remaining_rate > 0 THEN
                        random_rate := ROUND((random() * remaining_rate * 0.7)::NUMERIC, 4);
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
        END IF;
        
        -- グループ別週利データを挿入
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
            distribution_method,
            created_by
        ) VALUES (
            group_record.id,
            p_week_start_date,
            week_end_date,
            p_weekly_rate / 100,
            rates[1],
            rates[2],
            rates[3],
            rates[4],
            rates[5],
            p_distribution_method,
            p_admin_user_id
        );
        
        records_count := records_count + 1;
    END LOOP;
    
    RETURN QUERY SELECT 
        true,
        format('週利%s%%を%sに設定しました（%s件のグループ）', 
               p_weekly_rate, 
               p_week_start_date::TEXT, 
               records_count),
        records_count;
END;
$$ LANGUAGE plpgsql;

-- 5. 現在の週利設定関数を作成
CREATE OR REPLACE FUNCTION set_custom_weekly_rate(
    p_weekly_rate NUMERIC,
    p_distribution_method TEXT DEFAULT 'random'
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    week_start_date DATE
) AS $$
DECLARE
    current_week_start DATE;
    admin_user_id UUID;
BEGIN
    -- 今週の月曜日を取得
    current_week_start := DATE_TRUNC('week', CURRENT_DATE)::DATE + 1;
    
    -- 管理者ユーザーIDを取得
    SELECT id INTO admin_user_id FROM users WHERE user_id = 'admin001' LIMIT 1;
    
    -- 過去の週利設定関数を使用
    RETURN QUERY
    SELECT 
        shr.success,
        shr.message,
        current_week_start
    FROM set_historical_weekly_rate(
        current_week_start,
        p_weekly_rate,
        p_distribution_method,
        admin_user_id
    ) shr;
END;
$$ LANGUAGE plpgsql;

-- 6. 強制日利計算関数を作成
CREATE OR REPLACE FUNCTION force_daily_calculation()
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    calculations_performed INTEGER
) AS $$
DECLARE
    calc_count INTEGER := 0;
    target_date DATE;
    insert_count INTEGER;
BEGIN
    -- 今日から過去5日間の計算を実行
    FOR i IN 0..4 LOOP
        target_date := CURRENT_DATE - i;
        
        -- 平日のみ計算
        IF EXTRACT(DOW FROM target_date) BETWEEN 1 AND 5 THEN
            -- 日利計算を実行
            INSERT INTO daily_rewards (user_nft_id, user_id, reward_date, daily_rate, reward_amount, week_start_date, is_claimed)
            SELECT 
                un.id,
                un.user_id,
                target_date,
                CASE EXTRACT(DOW FROM target_date)
                    WHEN 1 THEN gwr.monday_rate
                    WHEN 2 THEN gwr.tuesday_rate
                    WHEN 3 THEN gwr.wednesday_rate
                    WHEN 4 THEN gwr.thursday_rate
                    WHEN 5 THEN gwr.friday_rate
                END,
                un.current_investment * (
                    CASE EXTRACT(DOW FROM target_date)
                        WHEN 1 THEN gwr.monday_rate
                        WHEN 2 THEN gwr.tuesday_rate
                        WHEN 3 THEN gwr.wednesday_rate
                        WHEN 4 THEN gwr.thursday_rate
                        WHEN 5 THEN gwr.friday_rate
                    END
                ),
                DATE_TRUNC('week', target_date)::DATE + 1,
                false
            FROM user_nfts un
            JOIN nfts n ON un.nft_id = n.id
            JOIN group_weekly_rates gwr ON n.group_id = gwr.group_id
            WHERE un.is_active = true
            AND gwr.week_start_date = DATE_TRUNC('week', target_date)::DATE + 1
            AND NOT EXISTS (
                SELECT 1 FROM daily_rewards dr 
                WHERE dr.user_nft_id = un.id AND dr.reward_date = target_date
            )
            -- 300%上限チェック
            AND (un.total_earned + un.current_investment * (
                CASE EXTRACT(DOW FROM target_date)
                    WHEN 1 THEN gwr.monday_rate
                    WHEN 2 THEN gwr.tuesday_rate
                    WHEN 3 THEN gwr.wednesday_rate
                    WHEN 4 THEN gwr.thursday_rate
                    WHEN 5 THEN gwr.friday_rate
                END
            )) <= un.max_earning;
            
            -- 挿入された行数を取得
            GET DIAGNOSTICS insert_count = ROW_COUNT;
            calc_count := calc_count + insert_count;
        END IF;
    END LOOP;
    
    RETURN QUERY SELECT 
        true,
        format('日利計算を実行しました（%s件）', calc_count),
        calc_count;
END;
$$ LANGUAGE plpgsql;

-- 7. 週利履歴取得関数を作成
CREATE OR REPLACE FUNCTION get_weekly_rates_history(
    p_limit INTEGER DEFAULT 50
) RETURNS TABLE(
    week_start_date DATE,
    week_end_date DATE,
    group_name TEXT,
    weekly_rate NUMERIC,
    monday_rate NUMERIC,
    tuesday_rate NUMERIC,
    wednesday_rate NUMERIC,
    thursday_rate NUMERIC,
    friday_rate NUMERIC,
    distribution_method TEXT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gwr.week_start_date,
        gwr.week_end_date,
        drg.group_name,
        gwr.weekly_rate,
        gwr.monday_rate,
        gwr.tuesday_rate,
        gwr.wednesday_rate,
        gwr.thursday_rate,
        gwr.friday_rate,
        COALESCE(gwr.distribution_method, 'random') as distribution_method,
        gwr.created_at
    FROM group_weekly_rates gwr
    JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- 8. 過去の週利一括設定関数を作成
CREATE OR REPLACE FUNCTION bulk_set_historical_rates(
    p_start_date DATE,
    p_end_date DATE,
    p_weekly_rate NUMERIC,
    p_distribution_method TEXT DEFAULT 'random'
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    weeks_processed INTEGER
) AS $$
DECLARE
    current_monday DATE;
    weeks_count INTEGER := 0;
    admin_user_id UUID;
BEGIN
    -- 管理者ユーザーIDを取得
    SELECT id INTO admin_user_id FROM users WHERE user_id = 'admin001' LIMIT 1;
    
    -- 開始日を月曜日に調整
    current_monday := DATE_TRUNC('week', p_start_date)::DATE + 1;
    
    -- 終了日まで週単位でループ
    WHILE current_monday <= p_end_date LOOP
        -- 各週の週利を設定
        PERFORM set_historical_weekly_rate(
            current_monday,
            p_weekly_rate,
            p_distribution_method,
            admin_user_id
        );
        
        weeks_count := weeks_count + 1;
        current_monday := current_monday + 7;
    END LOOP;
    
    RETURN QUERY SELECT 
        true,
        format('%s週間分の週利%s%%を設定しました', weeks_count, p_weekly_rate),
        weeks_count;
END;
$$ LANGUAGE plpgsql;

-- 9. テスト実行
SELECT 'Weekly rates system emergency restoration completed' as status;

-- 関数の存在確認
SELECT 
    'Function Check' as check_type,
    proname as function_name,
    'EXISTS' as status
FROM pg_proc 
WHERE proname IN (
    'get_weekly_rates_with_groups',
    'get_system_status',
    'set_historical_weekly_rate',
    'set_custom_weekly_rate',
    'force_daily_calculation',
    'get_weekly_rates_history',
    'bulk_set_historical_rates'
)
ORDER BY proname;
