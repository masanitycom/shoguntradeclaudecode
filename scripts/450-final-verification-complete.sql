-- 最終検証と完全なデバッグ

-- 1. NFT更新が効かない原因を徹底調査
DO $$
DECLARE
    nft_record RECORD;
    debug_msg TEXT;
    update_result INTEGER;
    constraint_info RECORD;
BEGIN
    debug_msg := '🔍 NFT更新失敗の原因調査開始';
    RAISE NOTICE '%', debug_msg;
    
    -- テーブル制約を確認
    FOR constraint_info IN
        SELECT 
            conname as constraint_name,
            contype as constraint_type,
            pg_get_constraintdef(oid) as constraint_definition
        FROM pg_constraint 
        WHERE conrelid = 'nfts'::regclass
    LOOP
        debug_msg := '🔒 制約: ' || constraint_info.constraint_name || ' (' || constraint_info.constraint_type || ')';
        RAISE NOTICE '%', debug_msg;
        debug_msg := '   定義: ' || constraint_info.constraint_definition;
        RAISE NOTICE '%', debug_msg;
    END LOOP;
    
    -- トリガーを確認
    FOR constraint_info IN
        SELECT 
            tgname as trigger_name,
            tgenabled as trigger_enabled
        FROM pg_trigger 
        WHERE tgrelid = 'nfts'::regclass
        AND tgname NOT LIKE 'RI_%'
    LOOP
        debug_msg := '⚡ トリガー: ' || constraint_info.trigger_name || ' (有効: ' || constraint_info.trigger_enabled || ')';
        RAISE NOTICE '%', debug_msg;
    END LOOP;
    
    -- 個別NFTの詳細情報を確認
    debug_msg := '📋 個別NFT詳細確認:';
    RAISE NOTICE '%', debug_msg;
    
    FOR nft_record IN
        SELECT id, name, price, daily_rate_limit, is_special, is_active, updated_at
        FROM nfts 
        WHERE name IN ('SHOGUN NFT 100', 'SHOGUN NFT 300', 'SHOGUN NFT 1000 (Special)')
        ORDER BY name
    LOOP
        debug_msg := '  NFT: ' || nft_record.name || 
                    ' | 価格: $' || nft_record.price ||
                    ' | 日利: ' || (nft_record.daily_rate_limit * 100) || '%' ||
                    ' | 特別: ' || nft_record.is_special ||
                    ' | アクティブ: ' || nft_record.is_active ||
                    ' | 更新日: ' || nft_record.updated_at;
        RAISE NOTICE '%', debug_msg;
    END LOOP;
END $$;

-- 2. 強制的な個別更新（トランザクション分離）
DO $$
DECLARE
    debug_msg TEXT;
    update_count INTEGER;
    total_updates INTEGER := 0;
BEGIN
    debug_msg := '🚀 強制個別更新開始（トランザクション分離）';
    RAISE NOTICE '%', debug_msg;
    
    -- 各NFTを個別のトランザクションで更新
    BEGIN
        UPDATE nfts SET daily_rate_limit = 0.005, updated_at = NOW() 
        WHERE name = 'SHOGUN NFT 100' AND is_special = true AND is_active = true;
        GET DIAGNOSTICS update_count = ROW_COUNT;
        total_updates := total_updates + update_count;
        debug_msg := '✅ SHOGUN NFT 100 (特別): ' || update_count || '件更新';
        RAISE NOTICE '%', debug_msg;
        COMMIT;
    EXCEPTION WHEN OTHERS THEN
        debug_msg := '❌ SHOGUN NFT 100 更新エラー: ' || SQLERRM;
        RAISE NOTICE '%', debug_msg;
        ROLLBACK;
    END;
    
    BEGIN
        UPDATE nfts SET daily_rate_limit = 0.005, updated_at = NOW() 
        WHERE name = 'SHOGUN NFT 200' AND is_special = true AND is_active = true;
        GET DIAGNOSTICS update_count = ROW_COUNT;
        total_updates := total_updates + update_count;
        debug_msg := '✅ SHOGUN NFT 200 (特別): ' || update_count || '件更新';
        RAISE NOTICE '%', debug_msg;
        COMMIT;
    EXCEPTION WHEN OTHERS THEN
        debug_msg := '❌ SHOGUN NFT 200 更新エラー: ' || SQLERRM;
        RAISE NOTICE '%', debug_msg;
        ROLLBACK;
    END;
    
    BEGIN
        UPDATE nfts SET daily_rate_limit = 0.005, updated_at = NOW() 
        WHERE name = 'SHOGUN NFT 300' AND is_special = false AND is_active = true;
        GET DIAGNOSTICS update_count = ROW_COUNT;
        total_updates := total_updates + update_count;
        debug_msg := '✅ SHOGUN NFT 300 (通常): ' || update_count || '件更新';
        RAISE NOTICE '%', debug_msg;
        COMMIT;
    EXCEPTION WHEN OTHERS THEN
        debug_msg := '❌ SHOGUN NFT 300 更新エラー: ' || SQLERRM;
        RAISE NOTICE '%', debug_msg;
        ROLLBACK;
    END;
    
    BEGIN
        UPDATE nfts SET daily_rate_limit = 0.005, updated_at = NOW() 
        WHERE name = 'SHOGUN NFT 500' AND is_special = false AND is_active = true;
        GET DIAGNOSTICS update_count = ROW_COUNT;
        total_updates := total_updates + update_count;
        debug_msg := '✅ SHOGUN NFT 500 (通常): ' || update_count || '件更新';
        RAISE NOTICE '%', debug_msg;
        COMMIT;
    EXCEPTION WHEN OTHERS THEN
        debug_msg := '❌ SHOGUN NFT 500 更新エラー: ' || SQLERRM;
        RAISE NOTICE '%', debug_msg;
        ROLLBACK;
    END;
    
    BEGIN
        UPDATE nfts SET daily_rate_limit = 0.005, updated_at = NOW() 
        WHERE name = 'SHOGUN NFT 600' AND is_special = true AND is_active = true;
        GET DIAGNOSTICS update_count = ROW_COUNT;
        total_updates := total_updates + update_count;
        debug_msg := '✅ SHOGUN NFT 600 (特別): ' || update_count || '件更新';
        RAISE NOTICE '%', debug_msg;
        COMMIT;
    EXCEPTION WHEN OTHERS THEN
        debug_msg := '❌ SHOGUN NFT 600 更新エラー: ' || SQLERRM;
        RAISE NOTICE '%', debug_msg;
        ROLLBACK;
    END;
    
    BEGIN
        UPDATE nfts SET daily_rate_limit = 0.0125, updated_at = NOW() 
        WHERE name = 'SHOGUN NFT 1000 (Special)' AND is_special = true AND is_active = true;
        GET DIAGNOSTICS update_count = ROW_COUNT;
        total_updates := total_updates + update_count;
        debug_msg := '✅ SHOGUN NFT 1000 (Special): ' || update_count || '件更新';
        RAISE NOTICE '%', debug_msg;
        COMMIT;
    EXCEPTION WHEN OTHERS THEN
        debug_msg := '❌ SHOGUN NFT 1000 (Special) 更新エラー: ' || SQLERRM;
        RAISE NOTICE '%', debug_msg;
        ROLLBACK;
    END;
    
    BEGIN
        UPDATE nfts SET daily_rate_limit = 0.0125, updated_at = NOW() 
        WHERE name = 'SHOGUN NFT 10000' AND is_special = false AND is_active = true;
        GET DIAGNOSTICS update_count = ROW_COUNT;
        total_updates := total_updates + update_count;
        debug_msg := '✅ SHOGUN NFT 10000 (通常): ' || update_count || '件更新';
        RAISE NOTICE '%', debug_msg;
        COMMIT;
    EXCEPTION WHEN OTHERS THEN
        debug_msg := '❌ SHOGUN NFT 10000 更新エラー: ' || SQLERRM;
        RAISE NOTICE '%', debug_msg;
        ROLLBACK;
    END;
    
    BEGIN
        UPDATE nfts SET daily_rate_limit = 0.015, updated_at = NOW() 
        WHERE name = 'SHOGUN NFT 30000' AND is_special = false AND is_active = true;
        GET DIAGNOSTICS update_count = ROW_COUNT;
        total_updates := total_updates + update_count;
        debug_msg := '✅ SHOGUN NFT 30000 (通常): ' || update_count || '件更新';
        RAISE NOTICE '%', debug_msg;
        COMMIT;
    EXCEPTION WHEN OTHERS THEN
        debug_msg := '❌ SHOGUN NFT 30000 更新エラー: ' || SQLERRM;
        RAISE NOTICE '%', debug_msg;
        ROLLBACK;
    END;
    
    debug_msg := '🎯 強制更新完了: 合計 ' || total_updates || '件';
    RAISE NOTICE '%', debug_msg;
END $$;

-- 3. 更新後の詳細確認
SELECT 
    '🔍 更新後詳細確認' as section,
    name,
    price,
    is_special,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    updated_at,
    CASE 
        WHEN daily_rate_limit = 0.005 THEN '✅ 0.5%グループ'
        WHEN daily_rate_limit = 0.010 THEN '⚠️ 1.0%グループ'
        WHEN daily_rate_limit = 0.0125 THEN '✅ 1.25%グループ'
        WHEN daily_rate_limit = 0.015 THEN '✅ 1.5%グループ'
        WHEN daily_rate_limit = 0.0175 THEN '✅ 1.75%グループ'
        WHEN daily_rate_limit = 0.020 THEN '✅ 2.0%グループ'
        ELSE '❌ 不明: ' || daily_rate_limit
    END as group_status
FROM nfts
WHERE is_active = true
ORDER BY daily_rate_limit, price, is_special DESC;

-- 4. グループ別最終分布
SELECT 
    '📊 最終グループ別分布' as section,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    COUNT(*) as nft_count,
    STRING_AGG(name || CASE WHEN is_special THEN '[特別]' ELSE '[通常]' END, ', ' ORDER BY price, name) as nft_names
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;

-- 5. システム状況最終確認
SELECT 
    '🎯 システム状況最終確認' as section,
    (SELECT COUNT(*) FROM user_nfts WHERE is_active = true AND current_investment > 0) as active_investments,
    (SELECT COUNT(*) FROM nfts WHERE is_active = true) as available_nfts,
    (SELECT COUNT(*) FROM group_weekly_rates WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)::DATE + INTERVAL '1 day') as current_week_settings,
    (SELECT COUNT(DISTINCT daily_rate_limit) FROM nfts WHERE is_active = true) as total_groups;

-- 6. 管理画面表示用データ確認
SELECT 
    '🖥️ 管理画面表示用データ' as section,
    drg.group_name,
    (drg.daily_rate_limit * 100) || '%' as displayed_rate,
    COUNT(n.id) as nft_count_for_ui,
    drg.description
FROM daily_rate_groups drg
LEFT JOIN nfts n ON n.daily_rate_limit = drg.daily_rate_limit AND n.is_active = true
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit, drg.description
ORDER BY drg.daily_rate_limit;
