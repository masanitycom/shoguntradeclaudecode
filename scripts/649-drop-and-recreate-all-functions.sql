-- 🚨 緊急：既存関数を全て削除してから再作成

-- 1. 既存関数を全て削除
DROP FUNCTION IF EXISTS emergency_system_diagnosis();
DROP FUNCTION IF EXISTS check_february_10_data();
DROP FUNCTION IF EXISTS get_system_status();
DROP FUNCTION IF EXISTS get_weekly_rates_with_groups();
DROP FUNCTION IF EXISTS set_group_weekly_rate(DATE, TEXT, NUMERIC);
DROP FUNCTION IF EXISTS force_daily_calculation();
DROP FUNCTION IF EXISTS admin_create_backup(DATE);
DROP FUNCTION IF EXISTS get_backup_list();
DROP FUNCTION IF EXISTS admin_delete_weekly_rates(DATE);
DROP FUNCTION IF EXISTS admin_restore_from_backup(DATE, TIMESTAMP);

-- 2. 緊急診断関数を作成
CREATE OR REPLACE FUNCTION emergency_system_diagnosis()
RETURNS TABLE(
    check_name TEXT,
    status TEXT,
    count_value BIGINT,
    details TEXT
) AS $$
BEGIN
    -- ユーザー数チェック
    RETURN QUERY
    SELECT 
        'total_users'::TEXT,
        'INFO'::TEXT,
        COUNT(*)::BIGINT,
        'アクティブユーザー数'::TEXT
    FROM users 
    WHERE created_at IS NOT NULL;
    
    -- NFT数チェック
    RETURN QUERY
    SELECT 
        'total_nfts'::TEXT,
        'INFO'::TEXT,
        COUNT(*)::BIGINT,
        '総NFT数'::TEXT
    FROM nfts;
    
    -- ユーザーNFT数チェック
    RETURN QUERY
    SELECT 
        'user_nfts'::TEXT,
        'INFO'::TEXT,
        COUNT(*)::BIGINT,
        'ユーザー保有NFT数'::TEXT
    FROM user_nfts;
    
    -- 週利設定チェック
    RETURN QUERY
    SELECT 
        'weekly_rates'::TEXT,
        'INFO'::TEXT,
        COUNT(*)::BIGINT,
        '設定済み週利数'::TEXT
    FROM group_weekly_rates;
    
    -- 日利報酬チェック
    RETURN QUERY
    SELECT 
        'daily_rewards'::TEXT,
        'INFO'::TEXT,
        COUNT(*)::BIGINT,
        '日利報酬レコード数'::TEXT
    FROM daily_rewards;
    
    -- テーブル存在チェック
    RETURN QUERY
    SELECT 
        'table_check'::TEXT,
        'INFO'::TEXT,
        COUNT(*)::BIGINT,
        '主要テーブル数'::TEXT
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name IN ('users', 'nfts', 'user_nfts', 'group_weekly_rates', 'daily_rewards');
    
END;
$$ LANGUAGE plpgsql;

-- 3. 2月10日データ確認関数
CREATE OR REPLACE FUNCTION check_february_10_data()
RETURNS TABLE(
    data_type TEXT,
    found BOOLEAN,
    count_value BIGINT,
    sample_data TEXT
) AS $$
BEGIN
    -- 2025-02-10の週利設定確認
    RETURN QUERY
    SELECT 
        'february_10_rates'::TEXT,
        EXISTS(SELECT 1 FROM group_weekly_rates WHERE week_start_date = '2025-02-10'),
        COUNT(*)::BIGINT,
        COALESCE(string_agg(group_id::TEXT, ', '), 'なし')::TEXT
    FROM group_weekly_rates 
    WHERE week_start_date = '2025-02-10';
    
    -- グループテーブル確認
    RETURN QUERY
    SELECT 
        'daily_rate_groups'::TEXT,
        EXISTS(SELECT 1 FROM daily_rate_groups),
        COUNT(*)::BIGINT,
        COALESCE(string_agg(group_name, ', '), 'なし')::TEXT
    FROM daily_rate_groups;
    
    -- 最新の週利設定確認
    RETURN QUERY
    SELECT 
        'latest_weekly_rates'::TEXT,
        EXISTS(SELECT 1 FROM group_weekly_rates),
        COUNT(*)::BIGINT,
        COALESCE(MAX(week_start_date)::TEXT, 'なし')::TEXT
    FROM group_weekly_rates;
    
END;
$$ LANGUAGE plpgsql;

-- 4. システム状況取得関数（管理画面用）
CREATE OR REPLACE FUNCTION get_system_status()
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total_users', (SELECT COUNT(*) FROM users),
        'active_nfts', (SELECT COUNT(*) FROM user_nfts WHERE purchase_price > 0),
        'pending_rewards', (SELECT COALESCE(SUM(reward_amount), 0) FROM daily_rewards WHERE reward_date >= CURRENT_DATE - INTERVAL '7 days'),
        'last_calculation', (SELECT COALESCE(MAX(created_at)::TEXT, '未実行') FROM daily_rewards),
        'current_week_rates', (SELECT COUNT(DISTINCT week_start_date) FROM group_weekly_rates),
        'total_backups', 0
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 5. 週利設定取得関数（管理画面用）- ORDER BY句を修正
CREATE OR REPLACE FUNCTION get_weekly_rates_with_groups()
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    -- サブクエリでORDER BYを使用してからjson_aggを適用
    WITH ordered_rates AS (
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
            COALESCE(drg.group_name, 'Unknown') as group_name,
            gwr.distribution_method,
            false as has_backup
        FROM group_weekly_rates gwr
        LEFT JOIN daily_rate_groups drg ON gwr.group_id = drg.id
        ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit
    )
    SELECT COALESCE(
        json_agg(
            json_build_object(
                'id', id,
                'week_start_date', week_start_date,
                'week_end_date', week_end_date,
                'weekly_rate', weekly_rate,
                'monday_rate', monday_rate,
                'tuesday_rate', tuesday_rate,
                'wednesday_rate', wednesday_rate,
                'thursday_rate', thursday_rate,
                'friday_rate', friday_rate,
                'group_name', group_name,
                'distribution_method', distribution_method,
                'has_backup', has_backup
            )
        ),
        '[]'::json
    ) INTO result
    FROM ordered_rates;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 6. 週利設定関数 - 変数名の曖昧性を修正
CREATE OR REPLACE FUNCTION set_group_weekly_rate(
    p_week_start_date DATE,
    p_group_name TEXT,
    p_weekly_rate NUMERIC
) RETURNS JSON AS $$
DECLARE
    week_end_date DATE;
    target_group_id UUID;  -- 変数名を変更して曖昧性を回避
    rates NUMERIC[] := ARRAY[0, 0, 0, 0, 0];
    remaining_rate NUMERIC;
    random_rate NUMERIC;
    i INTEGER;
    result JSON;
BEGIN
    week_end_date := p_week_start_date + 4;
    
    -- グループID取得
    SELECT id INTO target_group_id FROM daily_rate_groups WHERE group_name = p_group_name;
    
    IF target_group_id IS NULL THEN
        SELECT json_build_object(
            'success', false,
            'message', format('グループ "%s" が見つかりません', p_group_name)
        ) INTO result;
        RETURN result;
    END IF;
    
    -- 既存データ削除 - テーブル名を明示的に指定
    DELETE FROM group_weekly_rates 
    WHERE week_start_date = p_week_start_date AND group_weekly_rates.group_id = target_group_id;
    
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
        target_group_id,
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
    
    SELECT json_build_object(
        'success', true,
        'message', format('%s: %s%%設定完了', p_group_name, p_weekly_rate)
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 7. 強制日利計算関数
CREATE OR REPLACE FUNCTION force_daily_calculation()
RETURNS JSON AS $$
DECLARE
    today_date DATE := CURRENT_DATE;
    processed_count INTEGER := 0;
    result JSON;
BEGIN
    -- 平日チェック
    IF EXTRACT(DOW FROM today_date) IN (0, 6) THEN
        SELECT json_build_object(
            'success', false,
            'message', '土日は計算を実行しません',
            'calculation_date', today_date,
            'processed_count', 0
        ) INTO result;
        RETURN result;
    END IF;
    
    -- 簡易計算実行
    INSERT INTO daily_rewards (
        user_nft_id,
        reward_amount,
        reward_date,
        created_at,
        updated_at
    )
    SELECT 
        un.id,
        LEAST(un.purchase_price * 0.01, n.daily_rate_limit) as reward_amount,
        today_date,
        NOW(),
        NOW()
    FROM user_nfts un
    JOIN nfts n ON un.nft_id = n.id
    WHERE un.purchase_price > 0
    AND n.daily_rate_limit > 0
    ON CONFLICT (user_nft_id, reward_date) DO UPDATE SET
        reward_amount = EXCLUDED.reward_amount,
        updated_at = NOW();
    
    GET DIAGNOSTICS processed_count = ROW_COUNT;
    
    SELECT json_build_object(
        'success', true,
        'message', format('簡易計算完了: %s件処理', processed_count),
        'calculation_date', today_date,
        'processed_count', processed_count
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 8. バックアップ関連のダミー関数（後で実装）
CREATE OR REPLACE FUNCTION admin_create_backup(p_week_start_date DATE)
RETURNS JSON AS $$
BEGIN
    RETURN json_build_object(
        'success', true,
        'message', 'バックアップ機能は準備中です'
    );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_backup_list()
RETURNS JSON AS $$
BEGIN
    RETURN '[]'::json;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION admin_delete_weekly_rates(p_week_start_date DATE)
RETURNS JSON AS $$
BEGIN
    DELETE FROM group_weekly_rates WHERE week_start_date = p_week_start_date;
    
    RETURN json_build_object(
        'success', true,
        'message', format('%s の週利設定を削除しました', p_week_start_date)
    );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION admin_restore_from_backup(p_week_start_date DATE, p_backup_timestamp TIMESTAMP DEFAULT NULL)
RETURNS JSON AS $$
BEGIN
    RETURN json_build_object(
        'success', false,
        'message', 'バックアップ復元機能は準備中です'
    );
END;
$$ LANGUAGE plpgsql;

-- 9. 関数作成完了メッセージ
SELECT 'すべての関数が正常に作成されました！' as "作成結果";
