-- NFT更新問題の完全デバッグ（型キャスト修正版）

DO $$
DECLARE
    nft_record RECORD;
    debug_msg TEXT;
    update_result INTEGER;
    constraint_info RECORD;
BEGIN
    debug_msg := '🔍 NFT更新失敗の原因調査開始';
    RAISE NOTICE '%', debug_msg;
    
    -- テーブル制約を確認（型キャスト修正）
    FOR constraint_info IN
        SELECT 
            conname as constraint_name,
            contype::text as constraint_type,  -- 明示的にtext型にキャスト
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
            tgenabled::text as trigger_enabled  -- 明示的にtext型にキャスト
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
                    ' | 特別: ' || nft_record.is_special::text ||
                    ' | アクティブ: ' || nft_record.is_active::text ||
                    ' | 更新日: ' || nft_record.updated_at::text;
        RAISE NOTICE '%', debug_msg;
    END LOOP;
    
    -- 実際のWHERE条件をテスト
    debug_msg := '🧪 WHERE条件テスト:';
    RAISE NOTICE '%', debug_msg;
    
    -- SHOGUN NFT 100の条件確認
    SELECT COUNT(*) INTO update_result
    FROM nfts 
    WHERE name = 'SHOGUN NFT 100' AND is_special = true AND is_active = true;
    debug_msg := '  SHOGUN NFT 100 (特別・アクティブ): ' || update_result || '件該当';
    RAISE NOTICE '%', debug_msg;
    
    -- SHOGUN NFT 300の条件確認
    SELECT COUNT(*) INTO update_result
    FROM nfts 
    WHERE name = 'SHOGUN NFT 300' AND is_special = false AND is_active = true;
    debug_msg := '  SHOGUN NFT 300 (通常・アクティブ): ' || update_result || '件該当';
    RAISE NOTICE '%', debug_msg;
    
    -- SHOGUN NFT 1000 (Special)の条件確認
    SELECT COUNT(*) INTO update_result
    FROM nfts 
    WHERE name = 'SHOGUN NFT 1000 (Special)' AND is_special = true AND is_active = true;
    debug_msg := '  SHOGUN NFT 1000 (Special): ' || update_result || '件該当';
    RAISE NOTICE '%', debug_msg;
    
END $$;

-- 実際のNFTデータを詳細表示
SELECT 
    '📊 全NFT詳細データ' as section,
    id,
    name,
    price,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as current_rate,
    is_special,
    is_active,
    updated_at
FROM nfts
WHERE is_active = true
ORDER BY name;

-- 特定NFTの存在確認（boolean型MAX関数エラー修正）
SELECT 
    '🎯 特定NFT存在確認' as section,
    name,
    COUNT(*) as count,
    BOOL_OR(is_special) as has_special,  -- MAX(boolean)の代わりにBOOL_OR使用
    SUM(CASE WHEN is_special THEN 1 ELSE 0 END) as special_count,
    SUM(CASE WHEN NOT is_special THEN 1 ELSE 0 END) as normal_count
FROM nfts
WHERE name IN ('SHOGUN NFT 100', 'SHOGUN NFT 200', 'SHOGUN NFT 300', 'SHOGUN NFT 500', 'SHOGUN NFT 600', 'SHOGUN NFT 1000', 'SHOGUN NFT 1000 (Special)')
AND is_active = true
GROUP BY name
ORDER BY name;
