-- 週利設定UIデータの修正

-- 1. 🎯 今週の週利設定を確認・作成
DO $$
DECLARE
    current_week_start DATE;
    current_week_end DATE;
    settings_count INTEGER;
    group_record RECORD;
BEGIN
    -- 今週の開始日と終了日を計算（月曜日開始）
    current_week_start := DATE_TRUNC('week', CURRENT_DATE);
    current_week_end := current_week_start + INTERVAL '6 days';
    
    RAISE NOTICE '📅 今週の期間: % - %', current_week_start, current_week_end;
    
    -- 既存の今週設定をチェック
    SELECT COUNT(*) INTO settings_count
    FROM group_weekly_rates 
    WHERE week_start_date = current_week_start;
    
    RAISE NOTICE '📊 既存の今週設定数: %', settings_count;
    
    -- 設定が不足している場合は自動作成
    IF settings_count < 6 THEN
        RAISE NOTICE '🔧 不足している週利設定を自動作成中...';
        
        -- 各グループの設定を作成
        FOR group_record IN 
            SELECT DISTINCT daily_rate_limit
            FROM nfts 
            WHERE is_active = true
            ORDER BY daily_rate_limit
        LOOP
            -- 既存チェック
            IF NOT EXISTS (
                SELECT 1 FROM group_weekly_rates 
                WHERE week_start_date = current_week_start 
                AND group_daily_rate_limit = group_record.daily_rate_limit
            ) THEN
                -- デフォルト2.6%で作成
                INSERT INTO group_weekly_rates (
                    id,
                    week_start_date,
                    week_end_date,
                    group_daily_rate_limit,
                    weekly_rate,
                    created_at,
                    updated_at
                ) VALUES (
                    gen_random_uuid(),
                    current_week_start,
                    current_week_end,
                    group_record.daily_rate_limit,
                    0.026, -- 2.6%
                    NOW(),
                    NOW()
                );
                
                RAISE NOTICE '✅ 作成: %% グループ → 2.6%%', 
                    group_record.daily_rate_limit * 100;
            END IF;
        END LOOP;
    END IF;
    
    -- 最終確認
    SELECT COUNT(*) INTO settings_count
    FROM group_weekly_rates 
    WHERE week_start_date = current_week_start;
    
    RAISE NOTICE '✅ 今週の週利設定完了: %件', settings_count;
END $$;

-- 2. 📊 管理画面用統計データの更新
CREATE OR REPLACE VIEW admin_dashboard_stats AS
SELECT 
    (SELECT COUNT(*) FROM user_nfts WHERE is_active = true) as active_nft_investments,
    (SELECT COUNT(*) FROM nfts WHERE is_active = true) as available_nfts,
    (SELECT COUNT(*) FROM group_weekly_rates 
     WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)) as current_week_settings,
    CASE 
        WHEN EXTRACT(DOW FROM CURRENT_DATE) IN (1,2,3,4,5) THEN 
            TO_CHAR(CURRENT_DATE, 'Day') || ' 計算可能'
        ELSE 
            TO_CHAR(CURRENT_DATE, 'Day') || ' 計算停止'
    END as calculation_status;

-- 3. 🎯 NFTグループ別カウント用ビューの作成
CREATE OR REPLACE VIEW nft_group_counts AS
SELECT 
    drg.group_name,
    drg.daily_rate_limit,
    (drg.daily_rate_limit * 100) as display_rate,
    COUNT(n.id) as nft_count,
    CASE 
        WHEN drg.group_name = 'group_050' THEN '日利上限0.5%'
        WHEN drg.group_name = 'group_075' THEN '日利上限0.75%'
        WHEN drg.group_name = 'group_100' THEN '日利上限1.0%'
        WHEN drg.group_name = 'group_125' THEN '日利上限1.25%'
        WHEN drg.group_name = 'group_150' THEN '日利上限1.5%'
        WHEN drg.group_name = 'group_175' THEN '日利上限1.75%'
        WHEN drg.group_name = 'group_200' THEN '日利上限2.0%'
        ELSE '日利上限' || (drg.daily_rate_limit * 100) || '%'
    END as description
FROM daily_rate_groups drg
LEFT JOIN nfts n ON ABS(n.daily_rate_limit - drg.daily_rate_limit) < 0.0001
    AND n.is_active = true
GROUP BY drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;

-- 4. ✅ 修正完了確認
SELECT 
    '✅ UI修正完了確認' as status,
    (SELECT active_nft_investments || ' アクティブNFT投資' FROM admin_dashboard_stats) as stat1,
    (SELECT available_nfts || ' 利用可能NFT' FROM admin_dashboard_stats) as stat2,
    (SELECT current_week_settings || ' 今週の週利設定' FROM admin_dashboard_stats) as stat3,
    (SELECT calculation_status FROM admin_dashboard_stats) as stat4;
