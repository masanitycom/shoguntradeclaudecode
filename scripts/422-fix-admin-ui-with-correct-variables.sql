-- 管理画面UI表示の完全修正（変数名修正版）

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

-- 2. 今週の週利設定を自動作成（変数名修正版）
DO $$
DECLARE
    current_week_start DATE;
    group_limit NUMERIC;
    existing_count INTEGER;
    total_groups INTEGER;
    target_group_id UUID;
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
        SELECT id INTO target_group_id
        FROM daily_rate_groups 
        WHERE daily_rate_limit = group_limit
        LIMIT 1;
        
        -- target_group_idが見つからない場合は作成
        IF target_group_id IS NULL THEN
            target_group_id := gen_random_uuid();
            INSERT INTO daily_rate_groups (id, group_name, daily_rate_limit, description) 
            VALUES (
                target_group_id, 
                (group_limit * 100) || '%グループ', 
                group_limit, 
                '日利上限' || (group_limit * 100) || '%'
            );
            debug_msg := 'グループ作成: ' || (group_limit * 100)::TEXT || '% → ' || target_group_id;
            RAISE NOTICE '%', debug_msg;
        END IF;
        
        -- 既存の週利設定をチェック（変数名修正）
        IF NOT EXISTS (
            SELECT 1 FROM group_weekly_rates gwr
            WHERE gwr.week_start_date = current_week_start 
            AND gwr.group_id = target_group_id
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
                target_group_id,
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

-- 3. 管理画面のNFTカウント修正用ビュー（更新）
DROP VIEW IF EXISTS admin_weekly_rates_nft_groups;
CREATE VIEW admin_weekly_rates_nft_groups AS
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

-- 4. 管理画面表示テスト
SELECT 
    '📊 システム状況' as section,
    active_nft_investments || ' アクティブNFT投資' as stat1,
    available_nfts || ' 利用可能NFT' as stat2,
    current_week_settings || ' 今週の週利設定' as stat3,
    calculation_status as stat4
FROM get_admin_dashboard_stats();

-- 5. 管理画面コンポーネント用のクエリテスト
SELECT 
    '🔧 管理画面コンポーネント用データ' as test_section,
    id,
    group_name,
    daily_rate_limit,
    description,
    nft_count
FROM admin_weekly_rates_nft_groups;

-- 6. 最終確認
SELECT 
    '✅ 管理画面UI更新完了' as status,
    COUNT(DISTINCT daily_rate_limit) || '個のグループ' as groups,
    COUNT(*) || '個のNFT' as nfts,
    (SELECT COUNT(*) FROM group_weekly_rates 
     WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)::DATE) || '個の週利設定' as weekly_settings
FROM nfts
WHERE is_active = true;
