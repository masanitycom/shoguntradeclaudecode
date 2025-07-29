-- 実際のデータに基づく強制的なNFT分類修正

-- 1. まず現在の状況を確認
DO $$
DECLARE
    debug_msg TEXT;
    total_nfts INTEGER;
    unique_rates INTEGER;
BEGIN
    SELECT COUNT(*), COUNT(DISTINCT daily_rate_limit) 
    INTO total_nfts, unique_rates
    FROM nfts WHERE is_active = true;
    
    debug_msg := '🔍 現在の状況: ' || total_nfts || '個のNFT、' || unique_rates || '種類の日利上限';
    RAISE NOTICE '%', debug_msg;
END $$;

-- 2. 全NFTを価格に基づいて強制的に正しい日利上限に設定
DO $$
DECLARE
    nft_record RECORD;
    correct_rate NUMERIC;
    update_count INTEGER := 0;
    debug_msg TEXT;
BEGIN
    debug_msg := '🚀 全NFTの日利上限を価格に基づいて強制修正開始';
    RAISE NOTICE '%', debug_msg;
    
    FOR nft_record IN 
        SELECT id, name, price, daily_rate_limit, is_special
        FROM nfts 
        WHERE is_active = true
        ORDER BY price
    LOOP
        -- 価格帯による厳密な分類
        correct_rate := CASE
            WHEN nft_record.price <= 600 THEN 0.005    -- 0.5%
            WHEN nft_record.price <= 5000 THEN 0.010   -- 1.0%
            WHEN nft_record.price <= 10000 THEN 0.0125 -- 1.25%
            WHEN nft_record.price <= 30000 THEN 0.015  -- 1.5%
            WHEN nft_record.price <= 50000 THEN 0.0175 -- 1.75%
            ELSE 0.020                                  -- 2.0%
        END;
        
        -- 現在の値と異なる場合のみ更新
        IF ABS(nft_record.daily_rate_limit - correct_rate) > 0.0001 THEN
            UPDATE nfts 
            SET daily_rate_limit = correct_rate,
                updated_at = NOW()
            WHERE id = nft_record.id;
            
            update_count := update_count + 1;
            
            debug_msg := '更新: ' || nft_record.name || ' ($' || nft_record.price || ') ' ||
                        (nft_record.daily_rate_limit * 100) || '% → ' || (correct_rate * 100) || '%';
            RAISE NOTICE '%', debug_msg;
        END IF;
    END LOOP;
    
    debug_msg := '✅ NFT分類修正完了: ' || update_count || '件更新';
    RAISE NOTICE '%', debug_msg;
END $$;

-- 3. 不要なグループを削除し、必要なグループのみを作成
DO $$
DECLARE
    debug_msg TEXT;
BEGIN
    -- 既存のグループをクリア
    DELETE FROM daily_rate_groups;
    debug_msg := '🗑️ 既存グループを全削除';
    RAISE NOTICE '%', debug_msg;
    
    -- 実際に使用されている日利上限に基づいてグループを作成
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
    
    debug_msg := '✅ 実際のデータに基づいてグループを再作成';
    RAISE NOTICE '%', debug_msg;
END $$;

-- 4. 修正結果の確認
SELECT 
    '📊 修正後の分類結果' as result,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    COUNT(*) as nft_count,
    MIN(price) || '-' || MAX(price) as price_range,
    STRING_AGG(name, ', ' ORDER BY price) as nft_names
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;

-- 5. グループとNFTの対応確認
SELECT 
    '🎯 グループ別NFT数確認' as verification,
    drg.group_name,
    drg.daily_rate_limit,
    (drg.daily_rate_limit * 100) || '%' as rate_display,
    COUNT(n.id) as nft_count
FROM daily_rate_groups drg
LEFT JOIN nfts n ON n.daily_rate_limit = drg.daily_rate_limit
    AND n.is_active = true
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;

-- 6. 管理画面表示用の最終確認
SELECT 
    '✅ 管理画面表示確認' as final_check,
    COUNT(DISTINCT daily_rate_limit) as unique_groups,
    COUNT(*) as total_nfts,
    MIN(price) as min_price,
    MAX(price) as max_price
FROM nfts
WHERE is_active = true;

-- 7. 各グループの詳細
SELECT 
    '🔍 各グループの詳細' as group_details,
    CASE 
        WHEN daily_rate_limit = 0.005 THEN '0.5%グループ'
        WHEN daily_rate_limit = 0.010 THEN '1.0%グループ'
        WHEN daily_rate_limit = 0.0125 THEN '1.25%グループ'
        WHEN daily_rate_limit = 0.015 THEN '1.5%グループ'
        WHEN daily_rate_limit = 0.0175 THEN '1.75%グループ'
        WHEN daily_rate_limit = 0.020 THEN '2.0%グループ'
        ELSE 'その他'
    END as group_name,
    COUNT(*) || '種類' as nft_count_display,
    MIN(price) as min_price,
    MAX(price) as max_price,
    STRING_AGG(name || '($' || price || ')', ', ' ORDER BY price) as nft_list
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;
