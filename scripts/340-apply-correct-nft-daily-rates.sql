-- NFTの日利上限を仕様書に基づいて安全に修正するスクリプト
-- 外部キー制約を考慮した安全な更新処理

DO $$
DECLARE
    nft_record RECORD;
    update_count INTEGER := 0;
    error_count INTEGER := 0;
BEGIN
    RAISE NOTICE '🔧 NFTの日利上限修正を開始します...';
    
    -- 現在のNFTデータを確認
    RAISE NOTICE '📊 現在のNFTデータ:';
    FOR nft_record IN 
        SELECT id, name, price, daily_rate_limit 
        FROM nfts 
        ORDER BY price
    LOOP
        RAISE NOTICE '- ID: %, 名前: %, 価格: $%, 現在の日利上限: %', 
            nft_record.id, nft_record.name, nft_record.price, nft_record.daily_rate_limit;
    END LOOP;

    -- 仕様書に基づく日利上限の修正
    RAISE NOTICE '🎯 仕様書に基づく日利上限を適用中...';

    -- $300 NFT → 0.5%
    UPDATE nfts 
    SET daily_rate_limit = 0.5
    WHERE price = 300 AND daily_rate_limit != 0.5;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE '✅ $300 NFT: % 件更新', update_count;

    -- $500 NFT → 0.5%  
    UPDATE nfts 
    SET daily_rate_limit = 0.5
    WHERE price = 500 AND daily_rate_limit != 0.5;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE '✅ $500 NFT: % 件更新', update_count;

    -- $1000 NFT → 1.0%
    UPDATE nfts 
    SET daily_rate_limit = 1.0
    WHERE price = 1000 AND daily_rate_limit != 1.0;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE '✅ $1000 NFT: % 件更新', update_count;

    -- $1200 NFT → 1.0%
    UPDATE nfts 
    SET daily_rate_limit = 1.0
    WHERE price = 1200 AND daily_rate_limit != 1.0;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE '✅ $1200 NFT: % 件更新', update_count;

    -- $3000 NFT → 1.0%
    UPDATE nfts 
    SET daily_rate_limit = 1.0
    WHERE price = 3000 AND daily_rate_limit != 1.0;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE '✅ $3000 NFT: % 件更新', update_count;

    -- $5000 NFT → 1.0%
    UPDATE nfts 
    SET daily_rate_limit = 1.0
    WHERE price = 5000 AND daily_rate_limit != 1.0;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE '✅ $5000 NFT: % 件更新', update_count;

    -- $10000 NFT → 1.25%
    UPDATE nfts 
    SET daily_rate_limit = 1.25
    WHERE price = 10000 AND daily_rate_limit != 1.25;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE '✅ $10000 NFT: % 件更新', update_count;

    -- $30000 NFT → 1.5%
    UPDATE nfts 
    SET daily_rate_limit = 1.5
    WHERE price = 30000 AND daily_rate_limit != 1.5;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE '✅ $30000 NFT: % 件更新', update_count;

    -- $100000 NFT → 2.0%
    UPDATE nfts 
    SET daily_rate_limit = 2.0
    WHERE price = 100000 AND daily_rate_limit != 2.0;
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE '✅ $100000 NFT: % 件更新', update_count;

    -- 更新後のデータを確認
    RAISE NOTICE '📊 更新後のNFTデータ:';
    FOR nft_record IN 
        SELECT id, name, price, daily_rate_limit 
        FROM nfts 
        ORDER BY price
    LOOP
        RAISE NOTICE '- ID: %, 名前: %, 価格: $%, 日利上限: %', 
            nft_record.id, nft_record.name, nft_record.price, nft_record.daily_rate_limit;
    END LOOP;

    -- データ整合性チェック
    RAISE NOTICE '🔍 データ整合性チェック中...';
    
    -- 予期しない日利上限値をチェック
    FOR nft_record IN 
        SELECT id, name, price, daily_rate_limit 
        FROM nfts 
        WHERE daily_rate_limit NOT IN (0.5, 1.0, 1.25, 1.5, 2.0)
    LOOP
        RAISE WARNING '⚠️ 予期しない日利上限: ID %, 名前: %, 価格: $%, 日利上限: %', 
            nft_record.id, nft_record.name, nft_record.price, nft_record.daily_rate_limit;
        error_count := error_count + 1;
    END LOOP;

    -- 価格と日利上限の対応チェック
    SELECT COUNT(*) INTO update_count FROM nfts WHERE 
        (price = 300 AND daily_rate_limit != 0.5) OR
        (price = 500 AND daily_rate_limit != 0.5) OR
        (price = 1000 AND daily_rate_limit != 1.0) OR
        (price = 1200 AND daily_rate_limit != 1.0) OR
        (price = 3000 AND daily_rate_limit != 1.0) OR
        (price = 5000 AND daily_rate_limit != 1.0) OR
        (price = 10000 AND daily_rate_limit != 1.25) OR
        (price = 30000 AND daily_rate_limit != 1.5) OR
        (price = 100000 AND daily_rate_limit != 2.0);

    IF update_count > 0 THEN
        RAISE WARNING '⚠️ 仕様書と異なる日利上限のNFTが % 件あります', update_count;
        error_count := error_count + update_count;
    END IF;

    -- 結果サマリー
    RAISE NOTICE '📋 修正結果サマリー:';
    SELECT COUNT(*) INTO update_count FROM nfts;
    RAISE NOTICE '- 総NFT数: %', update_count;
    RAISE NOTICE '- エラー数: %', error_count;
    
    IF error_count = 0 THEN
        RAISE NOTICE '✅ NFTの日利上限修正が正常に完了しました';
    ELSE
        RAISE WARNING '⚠️ % 件のエラーがあります。確認が必要です', error_count;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION '❌ NFT日利上限修正中にエラーが発生しました: %', SQLERRM;
END $$;

-- 修正結果の確認クエリ
SELECT 
    price,
    daily_rate_limit,
    COUNT(*) as nft_count,
    STRING_AGG(name, ', ') as nft_names
FROM nfts 
GROUP BY price, daily_rate_limit 
ORDER BY price;
