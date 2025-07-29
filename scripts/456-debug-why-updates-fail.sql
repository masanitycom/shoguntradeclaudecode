-- なぜUPDATE文が効かないのかを徹底調査

DO $$
DECLARE
    debug_msg TEXT;
    test_count INTEGER;
    before_value DECIMAL;
    after_value DECIMAL;
    nft_id UUID;
BEGIN
    debug_msg := '🔍 UPDATE失敗の根本原因調査開始';
    RAISE NOTICE '%', debug_msg;
    
    -- 1. 特定NFTのIDを取得
    SELECT id, daily_rate_limit INTO nft_id, before_value
    FROM nfts 
    WHERE name = 'SHOGUN NFT 100' 
    AND is_active = true 
    LIMIT 1;
    
    debug_msg := '📋 SHOGUN NFT 100 ID: ' || nft_id || ', 現在値: ' || before_value;
    RAISE NOTICE '%', debug_msg;
    
    -- 2. 直接IDでUPDATE実行
    UPDATE nfts 
    SET daily_rate_limit = 0.005, updated_at = CURRENT_TIMESTAMP 
    WHERE id = nft_id;
    
    GET DIAGNOSTICS test_count = ROW_COUNT;
    debug_msg := '✅ UPDATE実行: ' || test_count || '行更新';
    RAISE NOTICE '%', debug_msg;
    
    -- 3. 更新後の値を確認
    SELECT daily_rate_limit INTO after_value
    FROM nfts 
    WHERE id = nft_id;
    
    debug_msg := '📊 更新後値: ' || after_value;
    RAISE NOTICE '%', debug_msg;
    
    -- 4. 値が変わったかチェック
    IF before_value != after_value THEN
        debug_msg := '✅ 更新成功: ' || before_value || ' → ' || after_value;
    ELSE
        debug_msg := '❌ 更新失敗: 値が変わっていません';
    END IF;
    RAISE NOTICE '%', debug_msg;
    
    -- 5. トランザクション状態確認
    debug_msg := '🔄 トランザクション状態: ' || txid_current();
    RAISE NOTICE '%', debug_msg;
    
END $$;

-- 即座に値を確認
SELECT 
    '🔍 即座確認' as section,
    name,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate,
    updated_at
FROM nfts 
WHERE name = 'SHOGUN NFT 100' 
AND is_active = true;
