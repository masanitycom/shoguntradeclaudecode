-- NFT分類の完全修正（変数名曖昧性エラー修正版）

-- 1. 現在のNFT状況を詳細確認
SELECT 
    '🔍 現在のNFT詳細状況' as info,
    name,
    price,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as current_rate,
    is_special,
    CASE 
        WHEN price <= 600 THEN '→ 0.5%グループ予定'
        WHEN price <= 5000 THEN '→ 1.0%グループ予定'
        WHEN price <= 10000 THEN '→ 1.25%グループ予定'
        WHEN price <= 30000 THEN '→ 1.5%グループ予定'
        WHEN price <= 50000 THEN '→ 1.75%グループ予定'
        ELSE '→ 2.0%グループ予定'
    END as expected_group
FROM nfts
WHERE is_active = true
ORDER BY price;

-- 2. 🎯 各NFTを価格帯で強制的に正しく分類
DO $$
DECLARE
    nft_info RECORD;
    correct_limit NUMERIC;
    classification_count INTEGER := 0;
    debug_msg TEXT;
BEGIN
    debug_msg := '🚀 NFT強制分類開始 - 価格帯による厳密分類';
    RAISE NOTICE '%', debug_msg;
    
    -- 全アクティブNFTを価格順で処理
    FOR nft_info IN 
        SELECT id, name, price, daily_rate_limit, is_special
        FROM nfts 
        WHERE is_active = true
        ORDER BY price
    LOOP
        -- 価格帯による厳密な分類（仕様書通り）
        correct_limit := CASE
            -- $600以下 → 0.5%
            WHEN nft_info.price <= 600 THEN 0.005
            -- $601-5000 → 1.0%
            WHEN nft_info.price <= 5000 THEN 0.010
            -- $5001-10000 → 1.25%
            WHEN nft_info.price <= 10000 THEN 0.0125
            -- $10001-30000 → 1.5%
            WHEN nft_info.price <= 30000 THEN 0.015
            -- $30001-50000 → 1.75%
            WHEN nft_info.price <= 50000 THEN 0.0175
            -- $50001以上 → 2.0%
            ELSE 0.020
        END;
        
        -- 更新実行（強制上書き）
        UPDATE nfts 
        SET daily_rate_limit = correct_limit,
            updated_at = NOW()
        WHERE id = nft_info.id;
        
        classification_count := classification_count + 1;
        
        -- デバッグ出力
        debug_msg := 'NFT分類: ' || nft_info.name || ' ($' || nft_info.price || ') → ' || 
                     (correct_limit * 100) || '%';
        RAISE NOTICE '%', debug_msg;
    END LOOP;
    
    debug_msg := 'NFT分類完了: ' || classification_count || '件処理';
    RAISE NOTICE '%', debug_msg;
END $$;

-- 3. 不要な0.75%グループを削除
DELETE FROM daily_rate_groups WHERE daily_rate_limit = 0.0075;

-- 4. 必要なグループのみを確実に作成
DO $$
DECLARE
    debug_msg TEXT;
BEGIN
    -- 0.5%グループ
    IF NOT EXISTS (SELECT 1 FROM daily_rate_groups WHERE daily_rate_limit = 0.005) THEN
        INSERT INTO daily_rate_groups (id, group_name, daily_rate_limit, description) 
        VALUES (gen_random_uuid(), '0.5%グループ', 0.005, '日利上限0.5%');
        debug_msg := '0.5%グループを作成しました';
        RAISE NOTICE '%', debug_msg;
    END IF;
    
    -- 1.0%グループ
    IF NOT EXISTS (SELECT 1 FROM daily_rate_groups WHERE daily_rate_limit = 0.010) THEN
        INSERT INTO daily_rate_groups (id, group_name, daily_rate_limit, description) 
        VALUES (gen_random_uuid(), '1.0%グループ', 0.010, '日利上限1.0%');
        debug_msg := '1.0%グループを作成しました';
        RAISE NOTICE '%', debug_msg;
    END IF;
    
    -- 1.25%グループ
    IF NOT EXISTS (SELECT 1 FROM daily_rate_groups WHERE daily_rate_limit = 0.0125) THEN
        INSERT INTO daily_rate_groups (id, group_name, daily_rate_limit, description) 
        VALUES (gen_random_uuid(), '1.25%グループ', 0.0125, '日利上限1.25%');
        debug_msg := '1.25%グループを作成しました';
        RAISE NOTICE '%', debug_msg;
    END IF;
    
    -- 1.5%グループ
    IF NOT EXISTS (SELECT 1 FROM daily_rate_groups WHERE daily_rate_limit = 0.015) THEN
        INSERT INTO daily_rate_groups (id, group_name, daily_rate_limit, description) 
        VALUES (gen_random_uuid(), '1.5%グループ', 0.015, '日利上限1.5%');
        debug_msg := '1.5%グループを作成しました';
        RAISE NOTICE '%', debug_msg;
    END IF;
    
    -- 1.75%グループ
    IF NOT EXISTS (SELECT 1 FROM daily_rate_groups WHERE daily_rate_limit = 0.0175) THEN
        INSERT INTO daily_rate_groups (id, group_name, daily_rate_limit, description) 
        VALUES (gen_random_uuid(), '1.75%グループ', 0.0175, '日利上限1.75%');
        debug_msg := '1.75%グループを作成しました';
        RAISE NOTICE '%', debug_msg;
    END IF;
    
    -- 2.0%グループ
    IF NOT EXISTS (SELECT 1 FROM daily_rate_groups WHERE daily_rate_limit = 0.020) THEN
        INSERT INTO daily_rate_groups (id, group_name, daily_rate_limit, description) 
        VALUES (gen_random_uuid(), '2.0%グループ', 0.020, '日利上限2.0%');
        debug_msg := '2.0%グループを作成しました';
        RAISE NOTICE '%', debug_msg;
    END IF;
END $$;

-- 5. 分類結果の詳細確認
SELECT 
    '📊 分類結果詳細' as status,
    CASE 
        WHEN daily_rate_limit = 0.005 THEN '0.5%グループ'
        WHEN daily_rate_limit = 0.010 THEN '1.0%グループ'
        WHEN daily_rate_limit = 0.0125 THEN '1.25%グループ'
        WHEN daily_rate_limit = 0.015 THEN '1.5%グループ'
        WHEN daily_rate_limit = 0.0175 THEN '1.75%グループ'
        WHEN daily_rate_limit = 0.020 THEN '2.0%グループ'
        ELSE '❌未分類(' || (daily_rate_limit * 100) || '%)'
    END as group_classification,
    COUNT(*) as nft_count,
    MIN(price) || '-' || MAX(price) as price_range,
    STRING_AGG(name, ', ' ORDER BY price) as nft_list
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;

-- 6. 管理画面表示用の最終確認
SELECT 
    '🎯 管理画面表示確認' as info,
    drg.group_name,
    (drg.daily_rate_limit * 100) || '%' as displayed_rate,
    COUNT(n.id) as actual_nft_count,
    CASE 
        WHEN COUNT(n.id) = 0 THEN '0種類'
        ELSE COUNT(n.id) || '種類'
    END as count_display
FROM daily_rate_groups drg
LEFT JOIN nfts n ON ABS(n.daily_rate_limit - drg.daily_rate_limit) < 0.0001
    AND n.is_active = true
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;

-- 7. 最終確認
SELECT 
    '✅ NFT分類修正完了' as status,
    COUNT(DISTINCT daily_rate_limit) as unique_groups,
    COUNT(*) as total_nfts,
    MIN(price) as min_price,
    MAX(price) as max_price
FROM nfts
WHERE is_active = true;
