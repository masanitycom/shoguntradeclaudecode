-- user_nfts テーブルの構造を確認し、必要に応じて修正するスクリプト

DO $$
DECLARE
    column_exists BOOLEAN;
    constraint_exists BOOLEAN;
    table_info RECORD;
BEGIN
    RAISE NOTICE '🔍 user_nfts テーブル構造チェック開始...';
    
    -- テーブルの存在確認
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_nfts') THEN
        RAISE EXCEPTION '❌ user_nfts テーブルが存在しません';
    END IF;
    
    RAISE NOTICE '✅ user_nfts テーブルが存在します';
    
    -- 現在のテーブル構造を確認
    RAISE NOTICE '📊 現在のテーブル構造:';
    FOR table_info IN
        SELECT 
            column_name,
            data_type,
            is_nullable,
            column_default
        FROM information_schema.columns
        WHERE table_name = 'user_nfts'
        ORDER BY ordinal_position
    LOOP
        RAISE NOTICE '- %: % (NULL: %, デフォルト: %)', 
            table_info.column_name, 
            table_info.data_type, 
            table_info.is_nullable, 
            COALESCE(table_info.column_default, 'なし');
    END LOOP;
    
    -- 必要なカラムの存在確認と追加
    
    -- purchase_amount カラムの確認
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_nfts' AND column_name = 'purchase_amount'
    ) INTO column_exists;
    
    IF NOT column_exists THEN
        RAISE NOTICE '⚠️ purchase_amount カラムが存在しません。追加します...';
        ALTER TABLE user_nfts ADD COLUMN purchase_amount DECIMAL(15,2) DEFAULT 0;
        RAISE NOTICE '✅ purchase_amount カラムを追加しました';
    ELSE
        RAISE NOTICE '✅ purchase_amount カラムが存在します';
    END IF;
    
    -- is_active カラムの確認
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_nfts' AND column_name = 'is_active'
    ) INTO column_exists;
    
    IF NOT column_exists THEN
        RAISE NOTICE '⚠️ is_active カラムが存在しません。追加します...';
        ALTER TABLE user_nfts ADD COLUMN is_active BOOLEAN DEFAULT true;
        RAISE NOTICE '✅ is_active カラムを追加しました';
    ELSE
        RAISE NOTICE '✅ is_active カラムが存在します';
    END IF;
    
    -- purchased_at カラムの確認
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_nfts' AND column_name = 'purchased_at'
    ) INTO column_exists;
    
    IF NOT column_exists THEN
        RAISE NOTICE '⚠️ purchased_at カラムが存在しません。追加します...';
        ALTER TABLE user_nfts ADD COLUMN purchased_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ purchased_at カラムを追加しました';
    ELSE
        RAISE NOTICE '✅ purchased_at カラムが存在します';
    END IF;
    
    -- completed_at カラムの確認
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_nfts' AND column_name = 'completed_at'
    ) INTO column_exists;
    
    IF NOT column_exists THEN
        RAISE NOTICE '⚠️ completed_at カラムが存在しません。追加します...';
        ALTER TABLE user_nfts ADD COLUMN completed_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ completed_at カラムを追加しました';
    ELSE
        RAISE NOTICE '✅ completed_at カラムが存在します';
    END IF;
    
    -- 外部キー制約の確認
    SELECT EXISTS (
        SELECT 1 FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
        WHERE tc.table_name = 'user_nfts' 
        AND tc.constraint_type = 'FOREIGN KEY'
        AND kcu.column_name = 'user_id'
    ) INTO constraint_exists;
    
    IF NOT constraint_exists THEN
        RAISE NOTICE '⚠️ user_id 外部キー制約が存在しません。追加します...';
        ALTER TABLE user_nfts 
        ADD CONSTRAINT fk_user_nfts_user_id 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ user_id 外部キー制約を追加しました';
    ELSE
        RAISE NOTICE '✅ user_id 外部キー制約が存在します';
    END IF;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
        WHERE tc.table_name = 'user_nfts' 
        AND tc.constraint_type = 'FOREIGN KEY'
        AND kcu.column_name = 'nft_id'
    ) INTO constraint_exists;
    
    IF NOT constraint_exists THEN
        RAISE NOTICE '⚠️ nft_id 外部キー制約が存在しません。追加します...';
        ALTER TABLE user_nfts 
        ADD CONSTRAINT fk_user_nfts_nft_id 
        FOREIGN KEY (nft_id) REFERENCES nfts(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ nft_id 外部キー制約を追加しました';
    ELSE
        RAISE NOTICE '✅ nft_id 外部キー制約が存在します';
    END IF;
    
    -- インデックスの確認と作成
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'user_nfts' AND indexname = 'idx_user_nfts_user_id') THEN
        CREATE INDEX idx_user_nfts_user_id ON user_nfts(user_id);
        RAISE NOTICE '✅ user_id インデックスを作成しました';
    ELSE
        RAISE NOTICE '✅ user_id インデックスが存在します';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'user_nfts' AND indexname = 'idx_user_nfts_nft_id') THEN
        CREATE INDEX idx_user_nfts_nft_id ON user_nfts(nft_id);
        RAISE NOTICE '✅ nft_id インデックスを作成しました';
    ELSE
        RAISE NOTICE '✅ nft_id インデックスが存在します';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'user_nfts' AND indexname = 'idx_user_nfts_is_active') THEN
        CREATE INDEX idx_user_nfts_is_active ON user_nfts(is_active);
        RAISE NOTICE '✅ is_active インデックスを作成しました';
    ELSE
        RAISE NOTICE '✅ is_active インデックスが存在します';
    END IF;
    
    -- データの整合性チェック
    RAISE NOTICE '🔍 データ整合性チェック...';
    
    -- purchase_amount が 0 のレコードをチェック
    SELECT COUNT(*) INTO column_exists FROM user_nfts WHERE purchase_amount = 0 OR purchase_amount IS NULL;
    IF column_exists > 0 THEN
        RAISE WARNING '⚠️ purchase_amount が 0 または NULL のレコードが % 件あります', column_exists;
        
        -- NFTの価格で purchase_amount を更新
        UPDATE user_nfts 
        SET purchase_amount = n.price
        FROM nfts n
        WHERE user_nfts.nft_id = n.id 
        AND (user_nfts.purchase_amount = 0 OR user_nfts.purchase_amount IS NULL);
        
        GET DIAGNOSTICS column_exists = ROW_COUNT;
        RAISE NOTICE '✅ % 件の purchase_amount を NFT価格で更新しました', column_exists;
    ELSE
        RAISE NOTICE '✅ purchase_amount データは正常です';
    END IF;
    
    -- 最終的なテーブル構造を表示
    RAISE NOTICE '📊 最終的なテーブル構造:';
    FOR table_info IN
        SELECT 
            column_name,
            data_type,
            is_nullable,
            column_default
        FROM information_schema.columns
        WHERE table_name = 'user_nfts'
        ORDER BY ordinal_position
    LOOP
        RAISE NOTICE '- %: % (NULL: %, デフォルト: %)', 
            table_info.column_name, 
            table_info.data_type, 
            table_info.is_nullable, 
            COALESCE(table_info.column_default, 'なし');
    END LOOP;
    
    -- テーブル統計情報
    SELECT COUNT(*) INTO column_exists FROM user_nfts;
    RAISE NOTICE '📊 user_nfts テーブル統計:';
    RAISE NOTICE '- 総レコード数: %', column_exists;
    
    SELECT COUNT(*) INTO column_exists FROM user_nfts WHERE is_active = true;
    RAISE NOTICE '- アクティブなNFT: %', column_exists;
    
    SELECT COUNT(*) INTO column_exists FROM user_nfts WHERE purchase_amount > 0;
    RAISE NOTICE '- 購入金額が設定されたNFT: %', column_exists;
    
    RAISE NOTICE '✅ user_nfts テーブル構造チェック完了';

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION '❌ user_nfts テーブル構造チェック中にエラーが発生しました: %', SQLERRM;
END $$;

-- テーブル構造の最終確認
SELECT 
    'user_nfts構造確認' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'user_nfts'
ORDER BY ordinal_position;
