-- daily_rewards テーブルの構造を確認・修正

-- 現在の構造を確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
ORDER BY ordinal_position;

-- nft_id カラムが存在するかチェックして追加
DO $$
BEGIN
    -- nft_id カラムが存在するかチェック
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'daily_rewards' 
        AND column_name = 'nft_id'
    ) THEN
        -- nft_id カラムを追加
        ALTER TABLE daily_rewards 
        ADD COLUMN nft_id UUID REFERENCES nfts(id);
        
        RAISE NOTICE 'nft_id カラムを追加しました';
    ELSE
        RAISE NOTICE 'nft_id カラムは既に存在します';
    END IF;
END $$;

-- user_nft_id カラムが存在する場合は、それを使ってnft_idを更新
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'daily_rewards' 
        AND column_name = 'user_nft_id'
    ) THEN
        -- user_nft_id から nft_id を取得して更新
        UPDATE daily_rewards 
        SET nft_id = (
            SELECT nft_id 
            FROM user_nfts 
            WHERE user_nfts.id = daily_rewards.user_nft_id
        )
        WHERE nft_id IS NULL AND user_nft_id IS NOT NULL;
        
        RAISE NOTICE 'user_nft_id から nft_id を更新しました';
    ELSE
        RAISE NOTICE 'user_nft_id カラムが存在しません';
    END IF;
END $$;

-- 必要なカラムが存在しない場合は追加
DO $$
BEGIN
    -- investment_amount カラムをチェック
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'daily_rewards' 
        AND column_name = 'investment_amount'
    ) THEN
        ALTER TABLE daily_rewards 
        ADD COLUMN investment_amount DECIMAL(15,2) DEFAULT 0;
        
        RAISE NOTICE 'investment_amount カラムを追加しました';
    END IF;
    
    -- daily_rate カラムをチェック
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'daily_rewards' 
        AND column_name = 'daily_rate'
    ) THEN
        ALTER TABLE daily_rewards 
        ADD COLUMN daily_rate DECIMAL(8,6) DEFAULT 0;
        
        RAISE NOTICE 'daily_rate カラムを追加しました';
    END IF;
    
    -- reward_date カラムをチェック
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'daily_rewards' 
        AND column_name = 'reward_date'
    ) THEN
        ALTER TABLE daily_rewards 
        ADD COLUMN reward_date DATE NOT NULL DEFAULT CURRENT_DATE;
        
        RAISE NOTICE 'reward_date カラムを追加しました';
    END IF;
END $$;

-- インデックスを追加
CREATE INDEX IF NOT EXISTS idx_daily_rewards_nft_id ON daily_rewards(nft_id);
CREATE INDEX IF NOT EXISTS idx_daily_rewards_user_nft_date ON daily_rewards(user_id, nft_id, reward_date);
CREATE INDEX IF NOT EXISTS idx_daily_rewards_date ON daily_rewards(reward_date);

-- ユニーク制約を追加（重複防止）
DO $$
BEGIN
    -- 既存の制約をチェック
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'daily_rewards' 
        AND constraint_name = 'daily_rewards_user_nft_date_unique'
    ) THEN
        ALTER TABLE daily_rewards 
        ADD CONSTRAINT daily_rewards_user_nft_date_unique 
        UNIQUE (user_id, nft_id, reward_date);
        
        RAISE NOTICE 'ユニーク制約を追加しました';
    ELSE
        RAISE NOTICE 'ユニーク制約は既に存在します';
    END IF;
END $$;

-- 修正後の構造確認
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
ORDER BY ordinal_position;

-- レコード数確認
SELECT 
    COUNT(*) as total_records,
    COUNT(nft_id) as records_with_nft_id,
    COUNT(user_id) as records_with_user_id
FROM daily_rewards;

SELECT 'daily_rewards テーブルの nft_id カラムを修正しました' as status;
