-- NFT分類の強制修正（RAISE構文エラー修正版）

-- 1. 🎯 各NFTを個別に正しいグループに分類
DO $$
DECLARE
    nft_info RECORD;
    correct_limit NUMERIC;
    classification_count INTEGER := 0;
    debug_msg TEXT;
BEGIN
    RAISE NOTICE '🚀 NFT個別分類の強制実行開始';
    
    -- 全アクティブNFTを処理
    FOR nft_info IN 
        SELECT id, name, price, daily_rate_limit, is_special
        FROM nfts 
        WHERE is_active = true
        ORDER BY price
    LOOP
        -- 価格帯による厳密な分類
        correct_limit := CASE
            -- $100以下 → 0.5%
            WHEN nft_info.price <= 100 THEN 0.005
            -- $101-200 → 0.5%
            WHEN nft_info.price <= 200 THEN 0.005
            -- $201-300 → 0.5%
            WHEN nft_info.price <= 300 THEN 0.005
            -- $301-500 → 0.5%
            WHEN nft_info.price <= 500 THEN 0.005
            -- $501-600 → 0.5%
            WHEN nft_info.price <= 600 THEN 0.005
            -- $601-1000 → 1.0%
            WHEN nft_info.price <= 1000 THEN 0.010
            -- $1001-1200 → 1.0%
            WHEN nft_info.price <= 1200 THEN 0.010
            -- $1201-3000 → 1.0%
            WHEN nft_info.price <= 3000 THEN 0.010
            -- $3001-5000 → 1.0%
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
        
        -- 特別NFTボーナス（小額のみ）
        IF nft_info.is_special AND correct_limit <= 0.010 THEN
            correct_limit := correct_limit + 0.0025; -- +0.25%
        END IF;
        
        -- 更新実行
        UPDATE nfts 
        SET daily_rate_limit = correct_limit,
            updated_at = NOW()
        WHERE id = nft_info.id;
        
        classification_count := classification_count + 1;
        
        -- デバッグメッセージを文字列連結で作成
        debug_msg := 'NFT分類: ' || nft_info.name || ' ($' || nft_info.price || ') → ' || 
                     (correct_limit * 100) || '% (特別:' || nft_info.is_special || ')';
        RAISE NOTICE '%', debug_msg;
    END LOOP;
    
    debug_msg := '✅ NFT分類完了: ' || classification_count || '件処理';
    RAISE NOTICE '%', debug_msg;
END $$;

-- 2. 分類結果の詳細確認
SELECT 
    '📊 分類結果詳細' as status,
    CASE 
        WHEN daily_rate_limit = 0.005 THEN '0.5%グループ'
        WHEN daily_rate_limit = 0.0075 THEN '0.75%グループ(特別)'
        WHEN daily_rate_limit = 0.010 THEN '1.0%グループ'
        WHEN daily_rate_limit = 0.0125 THEN '1.25%グループ'
        WHEN daily_rate_limit = 0.015 THEN '1.5%グループ'
        WHEN daily_rate_limit = 0.0175 THEN '1.75%グループ'
        WHEN daily_rate_limit = 0.020 THEN '2.0%グループ'
        ELSE '❌未分類(' || (daily_rate_limit * 100) || '%)'
    END as group_classification,
    COUNT(*) as nft_count,
    MIN(price) || '-' || MAX(price) as price_range,
    STRING_AGG(name, ', ' ORDER BY price) as sample_nfts
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;

-- 3. 🔧 daily_rate_groupsテーブルを実際の分類に合わせて更新（ON CONFLICT修正版）
DO $$
DECLARE
    debug_msg TEXT;
BEGIN
    -- 0.75%グループが存在しない場合のみ追加
    IF NOT EXISTS (SELECT 1 FROM daily_rate_groups WHERE daily_rate_limit = 0.0075) THEN
        INSERT INTO daily_rate_groups (id, group_name, daily_rate_limit, description) 
        VALUES (gen_random_uuid(), 'group_075', 0.0075, '特別NFT 0.75%グループ');
        RAISE NOTICE '✅ 0.75%グループを追加しました';
    END IF;
    
    -- 他の必要なグループも確認・追加
    IF NOT EXISTS (SELECT 1 FROM daily_rate_groups WHERE daily_rate_limit = 0.005) THEN
        INSERT INTO daily_rate_groups (id, group_name, daily_rate_limit, description) 
        VALUES (gen_random_uuid(), 'group_050', 0.005, '0.5%グループ');
        RAISE NOTICE '✅ 0.5%グループを追加しました';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM daily_rate_groups WHERE daily_rate_limit = 0.010) THEN
        INSERT INTO daily_rate_groups (id, group_name, daily_rate_limit, description) 
        VALUES (gen_random_uuid(), 'group_100', 0.010, '1.0%グループ');
        RAISE NOTICE '✅ 1.0%グループを追加しました';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM daily_rate_groups WHERE daily_rate_limit = 0.0125) THEN
        INSERT INTO daily_rate_groups (id, group_name, daily_rate_limit, description) 
        VALUES (gen_random_uuid(), 'group_125', 0.0125, '1.25%グループ');
        RAISE NOTICE '✅ 1.25%グループを追加しました';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM daily_rate_groups WHERE daily_rate_limit = 0.015) THEN
        INSERT INTO daily_rate_groups (id, group_name, daily_rate_limit, description) 
        VALUES (gen_random_uuid(), 'group_150', 0.015, '1.5%グループ');
        RAISE NOTICE '✅ 1.5%グループを追加しました';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM daily_rate_groups WHERE daily_rate_limit = 0.0175) THEN
        INSERT INTO daily_rate_groups (id, group_name, daily_rate_limit, description) 
        VALUES (gen_random_uuid(), 'group_175', 0.0175, '1.75%グループ');
        RAISE NOTICE '✅ 1.75%グループを追加しました';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM daily_rate_groups WHERE daily_rate_limit = 0.020) THEN
        INSERT INTO daily_rate_groups (id, group_name, daily_rate_limit, description) 
        VALUES (gen_random_uuid(), 'group_200', 0.020, '2.0%グループ');
        RAISE NOTICE '✅ 2.0%グループを追加しました';
    END IF;
END $$;

-- 4. 管理画面表示用の最終確認
SELECT 
    '🎯 管理画面表示確認' as info,
    drg.group_name,
    (drg.daily_rate_limit * 100) || '%' as displayed_rate,
    COUNT(n.id) as actual_nft_count,
    CASE 
        WHEN COUNT(n.id) = 0 THEN '❌ 0種類'
        ELSE COUNT(n.id) || '種類'
    END as count_display
FROM daily_rate_groups drg
LEFT JOIN nfts n ON ABS(n.daily_rate_limit - drg.daily_rate_limit) < 0.0001
    AND n.is_active = true
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;

-- 5. 📋 詳細なNFT一覧（デバッグ用）
SELECT 
    '🔍 NFT詳細一覧' as debug_info,
    name,
    price,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    is_special,
    CASE 
        WHEN daily_rate_limit = 0.005 THEN '0.5%グループ'
        WHEN daily_rate_limit = 0.0075 THEN '0.75%グループ'
        WHEN daily_rate_limit = 0.010 THEN '1.0%グループ'
        WHEN daily_rate_limit = 0.0125 THEN '1.25%グループ'
        WHEN daily_rate_limit = 0.015 THEN '1.5%グループ'
        WHEN daily_rate_limit = 0.0175 THEN '1.75%グループ'
        WHEN daily_rate_limit = 0.020 THEN '2.0%グループ'
        ELSE '未分類'
    END as assigned_group
FROM nfts
WHERE is_active = true
ORDER BY price, name;

-- 6. 🎯 管理画面用のグループ統計を更新
CREATE OR REPLACE VIEW admin_nft_group_display AS
SELECT 
    CASE 
        WHEN daily_rate_limit = 0.005 THEN '0.5%グループ'
        WHEN daily_rate_limit = 0.0075 THEN '0.75%グループ'
        WHEN daily_rate_limit = 0.010 THEN '1.0%グループ'
        WHEN daily_rate_limit = 0.0125 THEN '1.25%グループ'
        WHEN daily_rate_limit = 0.015 THEN '1.5%グループ'
        WHEN daily_rate_limit = 0.0175 THEN '1.75%グループ'
        WHEN daily_rate_limit = 0.020 THEN '2.0%グループ'
        ELSE 'その他グループ'
    END as group_name,
    (daily_rate_limit * 100) || '%' as daily_rate_display,
    COUNT(*) || '種類' as nft_count_display,
    '日利上限' || (daily_rate_limit * 100) || '%' as description
FROM nfts
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;

-- 7. ✅ 最終確認
SELECT 
    '✅ NFT分類修正完了' as status,
    COUNT(DISTINCT daily_rate_limit) as unique_groups,
    COUNT(*) as total_nfts,
    MIN(price) as min_price,
    MAX(price) as max_price
FROM nfts
WHERE is_active = true;
