-- 修正されたNFTデータに基づいて日利上限グループを再作成

-- 1. 既存のグループを全削除
DELETE FROM daily_rate_groups;

-- 2. 実際に使用されている日利上限に基づいてグループを作成
INSERT INTO daily_rate_groups (id, group_name, daily_rate_limit, description)
SELECT 
    gen_random_uuid(),
    CASE 
        WHEN daily_rate_limit = 0.005 THEN '0.5%グループ'
        WHEN daily_rate_limit = 0.010 THEN '1.0%グループ'
        WHEN daily_rate_limit = 0.0125 THEN '1.25%グループ'
        WHEN daily_rate_limit = 0.015 THEN '1.5%グループ'
        WHEN daily_rate_limit = 0.0175 THEN '1.75%グループ'
        WHEN daily_rate_limit = 0.020 THEN '2.0%グループ'
        ELSE (daily_rate_limit * 100) || '%グループ'
    END,
    daily_rate_limit,
    '日利上限' || (daily_rate_limit * 100) || '%'
FROM (
    SELECT DISTINCT daily_rate_limit
    FROM nfts 
    WHERE is_active = true
) rates
ORDER BY daily_rate_limit;

-- 3. グループとNFTの対応確認
SELECT 
    '🎯 グループ別NFT数確認' as verification,
    drg.group_name,
    drg.daily_rate_limit,
    (drg.daily_rate_limit * 100) || '%' as rate_display,
    COUNT(n.id) as nft_count,
    STRING_AGG(n.name, ', ' ORDER BY n.price) as nft_names
FROM daily_rate_groups drg
LEFT JOIN nfts n ON n.daily_rate_limit = drg.daily_rate_limit
    AND n.is_active = true
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;

-- 4. 管理画面表示用の統計
SELECT 
    '📊 管理画面表示用統計' as admin_stats,
    COUNT(DISTINCT n.daily_rate_limit) as unique_groups,
    COUNT(n.id) as total_nfts,
    COUNT(CASE WHEN gwr.week_start_date >= DATE_TRUNC('week', CURRENT_DATE) THEN 1 END) as current_week_settings
FROM nfts n
LEFT JOIN group_weekly_rates gwr ON gwr.week_start_date >= DATE_TRUNC('week', CURRENT_DATE)
WHERE n.is_active = true;

-- 5. 今週の週利設定を確認・作成
DO $$
DECLARE
    current_week_start DATE;
    group_record RECORD;
    setting_count INTEGER;
    debug_msg TEXT;
BEGIN
    current_week_start := DATE_TRUNC('week', CURRENT_DATE)::DATE;
    
    debug_msg := '📅 今週の週利設定確認: ' || current_week_start;
    RAISE NOTICE '%', debug_msg;
    
    FOR group_record IN 
        SELECT id, group_name, daily_rate_limit
        FROM daily_rate_groups
        ORDER BY daily_rate_limit
    LOOP
        SELECT COUNT(*) INTO setting_count
        FROM group_weekly_rates
        WHERE group_id = group_record.id
        AND week_start_date = current_week_start;
        
        IF setting_count = 0 THEN
            INSERT INTO group_weekly_rates (
                id, group_id, week_start_date, 
                monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate,
                created_at, updated_at
            ) VALUES (
                gen_random_uuid(), group_record.id, current_week_start,
                0.52, 0.52, 0.52, 0.52, 0.52,
                NOW(), NOW()
            );
            
            debug_msg := '✅ ' || group_record.group_name || 'の今週設定を作成';
            RAISE NOTICE '%', debug_msg;
        ELSE
            debug_msg := '✅ ' || group_record.group_name || 'の今週設定は既存';
            RAISE NOTICE '%', debug_msg;
        END IF;
    END LOOP;
    
    debug_msg := '🎯 今週の週利設定確認・作成完了';
    RAISE NOTICE '%', debug_msg;
END $$;

-- 6. 最終確認
SELECT 
    '✅ 最終確認' as final_verification,
    (SELECT COUNT(*) FROM daily_rate_groups) as total_groups,
    (SELECT COUNT(DISTINCT daily_rate_limit) FROM nfts WHERE is_active = true) as nft_rate_types,
    (SELECT COUNT(*) FROM group_weekly_rates WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)::DATE) as current_week_settings,
    CASE 
        WHEN (SELECT COUNT(*) FROM daily_rate_groups) = 
             (SELECT COUNT(DISTINCT daily_rate_limit) FROM nfts WHERE is_active = true)
        THEN '✅ グループとNFT分類が一致'
        ELSE '❌ グループとNFT分類が不一致'
    END as group_nft_match;
