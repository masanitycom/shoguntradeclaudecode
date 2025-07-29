-- daily_rewards テーブルの構造を確認し、必要に応じて修正するスクリプト

DO $$
DECLARE
    column_exists BOOLEAN;
    constraint_exists BOOLEAN;
    table_info RECORD;
    record_count INTEGER;
BEGIN
    RAISE NOTICE '🔍 daily_rewards テーブル構造チェック開始...';
    
    -- テーブルの存在確認
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'daily_rewards') THEN
        RAISE EXCEPTION '❌ daily_rewards テーブルが存在しません';
    END IF;
    
    RAISE NOTICE '✅ daily_rewards テーブルが存在します';
    
    -- 現在のテーブル構造を確認
    RAISE NOTICE '📊 現在のテーブル構造:';
    FOR table_info IN
        SELECT 
            column_name,
            data_type,
            is_nullable,
            column_default
        FROM information_schema.columns
        WHERE table_name = 'daily_rewards'
        ORDER BY ordinal_position
    LOOP
        RAISE NOTICE '- %: % (NULL: %, デフォルト: %)', 
            table_info.column_name, 
            table_info.data_type, 
            table_info.is_nullable, 
            COALESCE(table_info.column_default, 'なし');
    END LOOP;
    
    -- 必要なカラムの存在確認と追加
    
    -- updated_at カラムの確認
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'daily_rewards' AND column_name = 'updated_at'
    ) INTO column_exists;
    
    IF NOT column_exists THEN
        RAISE NOTICE '⚠️ updated_at カラムが存在しません。追加します...';
        ALTER TABLE daily_rewards ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ updated_at カラムを追加しました';
    ELSE
        RAISE NOTICE '✅ updated_at カラムが存在します';
    END IF;
    
    -- daily_rate カラムの確認
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'daily_rewards' AND column_name = 'daily_rate'
    ) INTO column_exists;
    
    IF NOT column_exists THEN
        RAISE NOTICE '⚠️ daily_rate カラムが存在しません。追加します...';
        ALTER TABLE daily_rewards ADD COLUMN daily_rate DECIMAL(5,2) DEFAULT 0;
        RAISE NOTICE '✅ daily_rate カラムを追加しました';
    ELSE
        RAISE NOTICE '✅ daily_rate カラムが存在します';
    END IF;
    
    -- investment_amount カラムの確認
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'daily_rewards' AND column_name = 'investment_amount'
    ) INTO column_exists;
    
    IF NOT column_exists THEN
        RAISE NOTICE '⚠️ investment_amount カラムが存在しません。追加します...';
        ALTER TABLE daily_rewards ADD COLUMN investment_amount DECIMAL(15,2) DEFAULT 0;
        RAISE NOTICE '✅ investment_amount カラムを追加しました';
    ELSE
        RAISE NOTICE '✅ investment_amount カラムが存在します';
    END IF;
    
    -- 外部キー制約の確認
    SELECT EXISTS (
        SELECT 1 FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
        WHERE tc.table_name = 'daily_rewards' 
        AND tc.constraint_type = 'FOREIGN KEY'
        AND kcu.column_name = 'user_id'
    ) INTO constraint_exists;
    
    IF NOT constraint_exists THEN
        RAISE NOTICE '⚠️ user_id 外部キー制約が存在しません。追加します...';
        ALTER TABLE daily_rewards 
        ADD CONSTRAINT fk_daily_rewards_user_id 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ user_id 外部キー制約を追加しました';
    ELSE
        RAISE NOTICE '✅ user_id 外部キー制約が存在します';
    END IF;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
        WHERE tc.table_name = 'daily_rewards' 
        AND tc.constraint_type = 'FOREIGN KEY'
        AND kcu.column_name = 'nft_id'
    ) INTO constraint_exists;
    
    IF NOT constraint_exists THEN
        RAISE NOTICE '⚠️ nft_id 外部キー制約が存在しません。追加します...';
        ALTER TABLE daily_rewards 
        ADD CONSTRAINT fk_daily_rewards_nft_id 
        FOREIGN KEY (nft_id) REFERENCES nfts(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ nft_id 外部キー制約を追加しました';
    ELSE
        RAISE NOTICE '✅ nft_id 外部キー制約が存在します';
    END IF;
    
    -- インデックスの確認と作成
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'daily_rewards' AND indexname = 'idx_daily_rewards_user_id') THEN
        CREATE INDEX idx_daily_rewards_user_id ON daily_rewards(user_id);
        RAISE NOTICE '✅ user_id インデックスを作成しました';
    ELSE
        RAISE NOTICE '✅ user_id インデックスが存在します';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'daily_rewards' AND indexname = 'idx_daily_rewards_nft_id') THEN
        CREATE INDEX idx_daily_rewards_nft_id ON daily_rewards(nft_id);
        RAISE NOTICE '✅ nft_id インデックスを作成しました';
    ELSE
        RAISE NOTICE '✅ nft_id インデックスが存在します';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'daily_rewards' AND indexname = 'idx_daily_rewards_reward_date') THEN
        CREATE INDEX idx_daily_rewards_reward_date ON daily_rewards(reward_date);
        RAISE NOTICE '✅ reward_date インデックスを作成しました';
    ELSE
        RAISE NOTICE '✅ reward_date インデックスが存在します';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'daily_rewards' AND indexname = 'idx_daily_rewards_user_nft_date') THEN
        CREATE INDEX idx_daily_rewards_user_nft_date ON daily_rewards(user_id, nft_id, reward_date);
        RAISE NOTICE '✅ 複合インデックス (user_id, nft_id, reward_date) を作成しました';
    ELSE
        RAISE NOTICE '✅ 複合インデックスが存在します';
    END IF;
    
    -- ユニーク制約の確認
    SELECT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_name = 'daily_rewards' 
        AND constraint_type = 'UNIQUE'
        AND constraint_name LIKE '%user_id%nft_id%reward_date%'
    ) INTO constraint_exists;
    
    IF NOT constraint_exists THEN
        RAISE NOTICE '⚠️ ユニーク制約が存在しません。追加します...';
        ALTER TABLE daily_rewards 
        ADD CONSTRAINT uk_daily_rewards_user_nft_date 
        UNIQUE (user_id, nft_id, reward_date);
        RAISE NOTICE '✅ ユニーク制約を追加しました';
    ELSE
        RAISE NOTICE '✅ ユニーク制約が存在します';
    END IF;
    
    -- データの整合性チェック
    RAISE NOTICE '🔍 データ整合性チェック...';
    
    -- 総レコード数
    SELECT COUNT(*) INTO record_count FROM daily_rewards;
    RAISE NOTICE '- 総レコード数: %', record_count;
    
    -- NULL値のチェック
    SELECT COUNT(*) INTO record_count FROM daily_rewards WHERE reward_amount IS NULL;
    IF record_count > 0 THEN
        RAISE WARNING '⚠️ reward_amount が NULL のレコードが % 件あります', record_count;
    END IF;
    
    SELECT COUNT(*) INTO record_count FROM daily_rewards WHERE daily_rate IS NULL;
    IF record_count > 0 THEN
        RAISE WARNING '⚠️ daily_rate が NULL のレコードが % 件あります', record_count;
        
        -- daily_rate を 0 で更新
        UPDATE daily_rewards SET daily_rate = 0 WHERE daily_rate IS NULL;
        GET DIAGNOSTICS record_count = ROW_COUNT;
        RAISE NOTICE '✅ % 件の daily_rate を 0 で更新しました', record_count;
    END IF;
    
    SELECT COUNT(*) INTO record_count FROM daily_rewards WHERE investment_amount IS NULL;
    IF record_count > 0 THEN
        RAISE WARNING '⚠️ investment_amount が NULL のレコードが % 件あります', record_count;
        
        -- investment_amount を user_nfts の purchase_amount で更新
        UPDATE daily_rewards 
        SET investment_amount = un.purchase_amount
        FROM user_nfts un
        WHERE daily_rewards.user_id = un.user_id 
        AND daily_rewards.nft_id = un.nft_id
        AND daily_rewards.investment_amount IS NULL;
        
        GET DIAGNOSTICS record_count = ROW_COUNT;
        RAISE NOTICE '✅ % 件の investment_amount を更新しました', record_count;
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
        WHERE table_name = 'daily_rewards'
        ORDER BY ordinal_position
    LOOP
        RAISE NOTICE '- %: % (NULL: %, デフォルト: %)', 
            table_info.column_name, 
            table_info.data_type, 
            table_info.is_nullable, 
            COALESCE(table_info.column_default, 'なし');
    END LOOP;
    
    -- テーブル統計情報
    SELECT COUNT(*) INTO record_count FROM daily_rewards;
    RAISE NOTICE '📊 daily_rewards テーブル統計:';
    RAISE NOTICE '- 総レコード数: %', record_count;
    
    SELECT COUNT(DISTINCT user_id) INTO record_count FROM daily_rewards;
    RAISE NOTICE '- ユニークユーザー数: %', record_count;
    
    SELECT COUNT(DISTINCT nft_id) INTO record_count FROM daily_rewards;
    RAISE NOTICE '- ユニークNFT数: %', record_count;
    
    SELECT COALESCE(SUM(reward_amount), 0) INTO record_count FROM daily_rewards;
    RAISE NOTICE '- 総報酬額: $%', record_count;
    
    RAISE NOTICE '✅ daily_rewards テーブル構造チェック完了';

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION '❌ daily_rewards テーブル構造チェック中にエラーが発生しました: %', SQLERRM;
END $$;

-- テーブル構造の最終確認
SELECT 
    'daily_rewards構造確認' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'daily_rewards'
ORDER BY ordinal_position;
