-- 管理画面UI表示の完全修正

-- 1. システム状況統計の更新
CREATE OR REPLACE FUNCTION get_admin_dashboard_stats()
RETURNS TABLE(
    active_nft_investments BIGINT,
    available_nfts BIGINT,
    current_week_settings BIGINT,
    calculation_status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM user_nfts WHERE is_active = true AND current_investment > 0),
        (SELECT COUNT(*) FROM nfts WHERE is_active = true),
        (SELECT COUNT(*) FROM group_weekly_rates 
         WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)::DATE),
        CASE 
            WHEN EXTRACT(DOW FROM CURRENT_DATE) BETWEEN 1 AND 5 THEN 
                CASE EXTRACT(DOW FROM CURRENT_DATE)
                    WHEN 1 THEN '月曜日 計算可能'
                    WHEN 2 THEN '火曜日 計算可能'
                    WHEN 3 THEN '水曜日 計算可能'
                    WHEN 4 THEN '木曜日 計算可能'
                    WHEN 5 THEN '金曜日 計算可能'
                END
            ELSE 
                CASE EXTRACT(DOW FROM CURRENT_DATE)
                    WHEN 6 THEN '土曜日 計算停止'
                    WHEN 0 THEN '日曜日 計算停止'
                END
        END;
END;
$$ LANGUAGE plpgsql;

-- 2. 日利上限グループの正確な表示データ
CREATE OR REPLACE FUNCTION get_nft_group_display()
RETURNS TABLE(
    group_name TEXT,
    daily_rate_display TEXT,
    nft_count_display TEXT,
    description TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CASE 
            WHEN n.daily_rate_limit = 0.005 THEN '0.5%グループ'
            WHEN n.daily_rate_limit = 0.0075 THEN '0.75%グループ'
            WHEN n.daily_rate_limit = 0.010 THEN '1.0%グループ'
            WHEN n.daily_rate_limit = 0.0125 THEN '1.25%グループ'
            WHEN n.daily_rate_limit = 0.015 THEN '1.5%グループ'
            WHEN n.daily_rate_limit = 0.0175 THEN '1.75%グループ'
            WHEN n.daily_rate_limit = 0.020 THEN '2.0%グループ'
            ELSE 'その他グループ'
        END,
        (n.daily_rate_limit * 100)::TEXT || '%',
        COUNT(*)::TEXT || '種類',
        '日利上限' || (n.daily_rate_limit * 100)::TEXT || '%'
    FROM nfts n
    WHERE n.is_active = true
    GROUP BY n.daily_rate_limit
    ORDER BY n.daily_rate_limit;
END;
$$ LANGUAGE plpgsql;

-- 3. 今週の週利設定を自動作成
DO $$
DECLARE
    current_week_start DATE;
    group_limit NUMERIC;
    existing_count INTEGER;
    total_groups INTEGER;
    group_id UUID;
    debug_msg TEXT;
BEGIN
    current_week_start := DATE_TRUNC('week', CURRENT_DATE)::DATE;
    
    -- 現在のアクティブなNFTグループを取得
    SELECT COUNT(DISTINCT daily_rate_limit) INTO total_groups
    FROM nfts WHERE is_active = true;
    
    -- 既存の今週設定数をチェック
    SELECT COUNT(*) INTO existing_count
    FROM group_weekly_rates 
    WHERE week_start_date = current_week_start;
    
    debug_msg := '今週設定: ' || existing_count || '/' || total_groups;
    RAISE NOTICE '%', debug_msg;
    
    -- 各グループに対して設定を確認・作成
    FOR group_limit IN 
        SELECT DISTINCT daily_rate_limit 
        FROM nfts 
        WHERE is_active = true
        ORDER BY daily_rate_limit
    LOOP
        -- 対応するdaily_rate_groupsのIDを取得
        SELECT id INTO group_id
        FROM daily_rate_groups 
        WHERE daily_rate_limit = group_limit
        LIMIT 1;
        
        -- group_idが見つからない場合は作成
        IF group_id IS NULL THEN
            group_id := gen_random_uuid();
            INSERT INTO daily_rate_groups (id, group_name, daily_rate_limit, description) 
            VALUES (
                group_id, 
                'group_' || REPLACE((group_limit * 100)::TEXT, '.', ''), 
                group_limit, 
                '日利上限' || (group_limit * 100) || '%グループ'
            );
            debug_msg := 'グループ作成: ' || (group_limit * 100)::TEXT || '% → ' || group_id;
            RAISE NOTICE '%', debug_msg;
        END IF;
        
        -- 既存の週利設定をチェック
        IF NOT EXISTS (
            SELECT 1 FROM group_weekly_rates 
            WHERE week_start_date = current_week_start 
            AND group_id = group_id
        ) THEN
            -- 設定を作成
            INSERT INTO group_weekly_rates (
                id,
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
                distribution_method,
                created_at,
                updated_at
            ) VALUES (
                gen_random_uuid(),
                group_id,
                current_week_start,
                current_week_start + 6,
                EXTRACT(WEEK FROM current_week_start)::INTEGER,
                0.026, -- デフォルト2.6%
                0.0052, -- 月曜 0.52%
                0.0052, -- 火曜 0.52%
                0.0052, -- 水曜 0.52%
                0.0052, -- 木曜 0.52%
                0.0052, -- 金曜 0.52%
                'equal_distribution',
                NOW(),
                NOW()
            );
            
            debug_msg := '週利設定作成: ' || (group_limit * 100)::TEXT || '% → 2.6%';
            RAISE NOTICE '%', debug_msg;
        END IF;
    END LOOP;
END $$;

-- 4. 管理画面表示テスト
SELECT 
    '📊 システム状況' as section,
    active_nft_investments || ' アクティブNFT投資' as stat1,
    available_nfts || ' 利用可能NFT' as stat2,
    current_week_settings || ' 今週の週利設定' as stat3,
    calculation_status as stat4
FROM get_admin_dashboard_stats();

-- 5. 日利上限グループ表示テスト
SELECT 
    '🎯 日利上限グループ' as section,
    group_name,
    daily_rate_display as 日利上限,
    nft_count_display as NFT数,
    description as 説明
FROM get_nft_group_display();

-- 6. 管理画面のNFTカウント修正用ビュー
CREATE OR REPLACE VIEW admin_weekly_rates_nft_groups AS
SELECT 
    drg.id,
    drg.group_name,
    drg.daily_rate_limit,
    drg.description,
    COALESCE(nft_counts.nft_count, 0) as nft_count
FROM daily_rate_groups drg
LEFT JOIN (
    SELECT 
        daily_rate_limit,
        COUNT(*) as nft_count
    FROM nfts 
    WHERE is_active = true
    GROUP BY daily_rate_limit
) nft_counts ON ABS(drg.daily_rate_limit - nft_counts.daily_rate_limit) < 0.0001
ORDER BY drg.daily_rate_limit;

-- 7. 最終確認
SELECT 
    '✅ 管理画面UI更新完了' as status,
    COUNT(DISTINCT daily_rate_limit) || '個のグループ' as groups,
    COUNT(*) || '個のNFT' as nfts,
    (SELECT COUNT(*) FROM group_weekly_rates 
     WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)::DATE) || '個の週利設定' as weekly_settings
FROM nfts
WHERE is_active = true;

-- 8. 管理画面コンポーネント用のクエリテスト
SELECT 
    '🔧 管理画面コンポーネント用データ' as test_section,
    id,
    group_name,
    daily_rate_limit,
    description,
    nft_count
FROM admin_weekly_rates_nft_groups;
