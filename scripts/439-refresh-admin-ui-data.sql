-- 管理画面データのリフレッシュとキャッシュクリア

DO $$
DECLARE
    debug_msg TEXT;
    group_count INTEGER;
    week_count INTEGER;
BEGIN
    debug_msg := '🔄 管理画面データリフレッシュ開始';
    RAISE NOTICE '%', debug_msg;
    
    -- daily_rate_groupsテーブルを完全に再構築
    DELETE FROM daily_rate_groups;
    
    -- 実際のNFTデータに基づいてグループを作成
    INSERT INTO daily_rate_groups (id, group_name, daily_rate_limit, description)
    SELECT 
        gen_random_uuid(),
        (daily_rate_limit * 100) || '%グループ',
        daily_rate_limit,
        '日利上限' || (daily_rate_limit * 100) || '%'
    FROM (
        SELECT DISTINCT daily_rate_limit
        FROM nfts
        WHERE is_active = true
        ORDER BY daily_rate_limit
    ) rates;
    
    GET DIAGNOSTICS group_count = ROW_COUNT;
    debug_msg := '✅ 日利グループ再作成: ' || group_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    -- 今週の週利設定を確認
    SELECT COUNT(*) INTO week_count
    FROM group_weekly_rates
    WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day';
    
    debug_msg := '📊 今週の週利設定: ' || week_count || '件';
    RAISE NOTICE '%', debug_msg;
    
    -- 週利設定がない場合は作成
    IF week_count = 0 THEN
        INSERT INTO group_weekly_rates (
            id, group_id, week_start_date, week_end_date, week_number,
            weekly_rate, monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate,
            distribution_method, created_at, updated_at
        )
        SELECT 
            gen_random_uuid(),
            drg.id,
            DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day',
            DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '7 days',
            EXTRACT(week FROM CURRENT_DATE)::INTEGER,
            0.026, -- 2.6%
            0.005, 0.006, 0.005, 0.005, 0.005, -- ランダム配分例
            'random_distribution',
            NOW(),
            NOW()
        FROM daily_rate_groups drg;
        
        GET DIAGNOSTICS week_count = ROW_COUNT;
        debug_msg := '✅ 今週の週利設定作成: ' || week_count || '件';
        RAISE NOTICE '%', debug_msg;
    END IF;
    
    debug_msg := '🎯 管理画面データリフレッシュ完了';
    RAISE NOTICE '%', debug_msg;
END $$;

-- 管理画面表示用データの最終確認
SELECT 
    '📊 管理画面表示用最終確認' as section,
    (SELECT COUNT(*) FROM user_nfts WHERE is_active = true AND current_investment > 0) as active_investments,
    (SELECT COUNT(*) FROM nfts WHERE is_active = true) as available_nfts,
    (SELECT COUNT(*) FROM group_weekly_rates WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day') as current_week_settings,
    (SELECT COUNT(*) FROM daily_rate_groups) as total_groups;

-- グループ別NFT数の確認
SELECT 
    '🎯 グループ別NFT分布' as section,
    drg.group_name,
    drg.daily_rate_limit,
    (drg.daily_rate_limit * 100) || '%' as rate_display,
    COUNT(n.id) as nft_count,
    STRING_AGG(n.name, ', ' ORDER BY n.price) as nft_names
FROM daily_rate_groups drg
LEFT JOIN nfts n ON n.daily_rate_limit = drg.daily_rate_limit AND n.is_active = true
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;
