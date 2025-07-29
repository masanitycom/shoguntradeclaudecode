-- 特定週の週利管理機能を追加

-- 1. 特定週の週利設定を削除する関数
CREATE OR REPLACE FUNCTION delete_specific_week_rates(
    p_week_start_date DATE
) RETURNS TABLE(
    deleted_count INTEGER,
    message TEXT
) AS $$
DECLARE
    delete_count INTEGER := 0;
BEGIN
    -- 指定された週の設定を削除
    DELETE FROM group_weekly_rates 
    WHERE week_start_date = p_week_start_date;
    
    GET DIAGNOSTICS delete_count = ROW_COUNT;
    
    RETURN QUERY SELECT 
        delete_count,
        CASE 
            WHEN delete_count > 0 THEN 
                '✅ ' || delete_count || '件の週利設定を削除しました'
            ELSE 
                '⚠️ 指定された週の設定が見つかりませんでした'
        END;
END;
$$ LANGUAGE plpgsql;

-- 2. 特定週の週利設定を上書きする関数
CREATE OR REPLACE FUNCTION overwrite_specific_week_rates(
    p_week_start_date DATE,
    p_group_id UUID,
    p_weekly_rate NUMERIC
) RETURNS TABLE(
    action_taken TEXT,
    message TEXT
) AS $$
DECLARE
    existing_count INTEGER := 0;
BEGIN
    -- 既存の設定があるかチェック
    SELECT COUNT(*) INTO existing_count
    FROM group_weekly_rates
    WHERE week_start_date = p_week_start_date 
    AND group_id = p_group_id;
    
    IF existing_count > 0 THEN
        -- 既存設定を上書き
        DELETE FROM group_weekly_rates 
        WHERE week_start_date = p_week_start_date 
        AND group_id = p_group_id;
        
        -- 新しい設定を作成
        PERFORM create_synchronized_weekly_distribution(
            p_week_start_date,
            p_group_id,
            p_weekly_rate
        );
        
        RETURN QUERY SELECT 
            'overwrite'::TEXT,
            '✅ 既存設定を上書きしました'::TEXT;
    ELSE
        -- 新規作成
        PERFORM create_synchronized_weekly_distribution(
            p_week_start_date,
            p_group_id,
            p_weekly_rate
        );
        
        RETURN QUERY SELECT 
            'create'::TEXT,
            '✅ 新規設定を作成しました'::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 3. 特定週の設定状況を確認する関数
CREATE OR REPLACE FUNCTION check_specific_week_status(
    p_week_start_date DATE
) RETURNS TABLE(
    group_name TEXT,
    weekly_rate_percent NUMERIC,
    monday_rate_percent NUMERIC,
    tuesday_rate_percent NUMERIC,
    wednesday_rate_percent NUMERIC,
    thursday_rate_percent NUMERIC,
    friday_rate_percent NUMERIC,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        drg.group_name,
        (gwr.weekly_rate * 100)::NUMERIC as weekly_rate_percent,
        (gwr.monday_rate * 100)::NUMERIC as monday_rate_percent,
        (gwr.tuesday_rate * 100)::NUMERIC as tuesday_rate_percent,
        (gwr.wednesday_rate * 100)::NUMERIC as wednesday_rate_percent,
        (gwr.thursday_rate * 100)::NUMERIC as thursday_rate_percent,
        (gwr.friday_rate * 100)::NUMERIC as friday_rate_percent,
        gwr.created_at
    FROM group_weekly_rates gwr
    JOIN daily_rate_groups drg ON gwr.group_id = drg.id
    WHERE gwr.week_start_date = p_week_start_date
    ORDER BY drg.daily_rate_limit;
END;
$$ LANGUAGE plpgsql;

-- 4. 🎯 2025/7/7-7/13の週の現在の設定を確認
SELECT 
    '🔍 2025/7/7-7/13週の現在設定' as info,
    *
FROM check_specific_week_status('2025-07-07');

-- 5. 週利設定の一覧表示（最新10週分）
SELECT 
    '📋 最新の週利設定一覧' as info,
    gwr.week_start_date,
    gwr.week_start_date + INTERVAL '6 days' as week_end_date,
    drg.group_name,
    (gwr.weekly_rate * 100)::NUMERIC(5,2) as weekly_rate_percent,
    gwr.created_at
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date >= CURRENT_DATE - INTERVAL '70 days'
ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit
LIMIT 50;

-- 6. 特定週削除のテスト（実際には実行しない）
SELECT 
    '🧪 特定週削除テスト（2025/7/7週）' as info,
    '実行コマンド: SELECT * FROM delete_specific_week_rates(''2025-07-07'');' as 削除コマンド,
    '実行コマンド: SELECT * FROM overwrite_specific_week_rates(''2025-07-07'', group_id, 3.5);' as 上書きコマンド,
    '⚠️ 実際の削除は管理画面から行ってください' as 注意;
