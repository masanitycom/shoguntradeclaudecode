-- テーブル構造を完全に修正

-- 1. user_nftsテーブルに必要なカラムを追加
DO $$
BEGIN
    -- investment_amountカラムが存在しない場合は追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_nfts' 
        AND column_name = 'investment_amount'
    ) THEN
        ALTER TABLE user_nfts ADD COLUMN investment_amount DECIMAL(15,2) DEFAULT 0;
        RAISE NOTICE 'user_nfts.investment_amount カラムを追加しました';
        
        -- 既存データの investment_amount を purchase_price で初期化
        UPDATE user_nfts SET investment_amount = COALESCE(purchase_price, 0);
        RAISE NOTICE 'investment_amount を purchase_price で初期化しました';
    ELSE
        RAISE NOTICE 'user_nfts.investment_amount カラムは既に存在します';
    END IF;
    
    -- current_investmentカラムが存在しない場合は追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_nfts' 
        AND column_name = 'current_investment'
    ) THEN
        ALTER TABLE user_nfts ADD COLUMN current_investment DECIMAL(15,2) DEFAULT 0;
        RAISE NOTICE 'user_nfts.current_investment カラムを追加しました';
        
        -- 既存データの current_investment を purchase_price で初期化
        UPDATE user_nfts SET current_investment = COALESCE(purchase_price, 0);
        RAISE NOTICE 'current_investment を purchase_price で初期化しました';
    ELSE
        RAISE NOTICE 'user_nfts.current_investment カラムは既に存在します';
    END IF;
    
    -- total_earnedカラムが存在しない場合は追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_nfts' 
        AND column_name = 'total_earned'
    ) THEN
        ALTER TABLE user_nfts ADD COLUMN total_earned DECIMAL(15,2) DEFAULT 0;
        RAISE NOTICE 'user_nfts.total_earned カラムを追加しました';
    ELSE
        RAISE NOTICE 'user_nfts.total_earned カラムは既に存在します';
    END IF;
    
    -- max_earningカラムが存在しない場合は追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_nfts' 
        AND column_name = 'max_earning'
    ) THEN
        ALTER TABLE user_nfts ADD COLUMN max_earning DECIMAL(15,2) DEFAULT 0;
        RAISE NOTICE 'user_nfts.max_earning カラムを追加しました';
        
        -- max_earning を purchase_price * 3 で初期化（300%キャップ）
        UPDATE user_nfts SET max_earning = COALESCE(purchase_price, 0) * 3;
        RAISE NOTICE 'max_earning を purchase_price * 3 で初期化しました';
    ELSE
        RAISE NOTICE 'user_nfts.max_earning カラムは既に存在します';
    END IF;
END $$;

-- 2. nftsテーブルにdaily_rate_group_idカラムを追加
DO $$
BEGIN
    -- daily_rate_group_idカラムが存在しない場合は追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'nfts' 
        AND column_name = 'daily_rate_group_id'
    ) THEN
        ALTER TABLE nfts ADD COLUMN daily_rate_group_id UUID;
        RAISE NOTICE 'nfts.daily_rate_group_id カラムを追加しました';
        
        -- 既存のNFTにグループIDを設定
        UPDATE nfts SET daily_rate_group_id = (
            SELECT drg.id 
            FROM daily_rate_groups drg 
            WHERE drg.daily_rate_limit = nfts.daily_rate_limit
            LIMIT 1
        );
        
        RAISE NOTICE 'NFTにグループIDを設定しました';
        
        -- 外部キー制約を追加
        ALTER TABLE nfts 
        ADD CONSTRAINT fk_nfts_daily_rate_group 
        FOREIGN KEY (daily_rate_group_id) REFERENCES daily_rate_groups(id);
        
        RAISE NOTICE '外部キー制約を追加しました';
    ELSE
        RAISE NOTICE 'nfts.daily_rate_group_id カラムは既に存在します';
    END IF;
END $$;

-- 3. daily_rewardsテーブルの構造を確認・修正
DO $$
BEGIN
    -- user_nft_idカラムが存在しない場合は追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'daily_rewards' 
        AND column_name = 'user_nft_id'
    ) THEN
        ALTER TABLE daily_rewards ADD COLUMN user_nft_id UUID;
        RAISE NOTICE 'daily_rewards.user_nft_id カラムを追加しました';
    ELSE
        RAISE NOTICE 'daily_rewards.user_nft_id カラムは既に存在します';
    END IF;
    
    -- investment_amountカラムが存在しない場合は追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'daily_rewards' 
        AND column_name = 'investment_amount'
    ) THEN
        ALTER TABLE daily_rewards ADD COLUMN investment_amount DECIMAL(15,2) DEFAULT 0;
        RAISE NOTICE 'daily_rewards.investment_amount カラムを追加しました';
    ELSE
        RAISE NOTICE 'daily_rewards.investment_amount カラムは既に存在します';
    END IF;
    
    -- reward_typeカラムが存在しない場合は追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'daily_rewards' 
        AND column_name = 'reward_type'
    ) THEN
        ALTER TABLE daily_rewards ADD COLUMN reward_type VARCHAR(50) DEFAULT 'DAILY_REWARD';
        RAISE NOTICE 'daily_rewards.reward_type カラムを追加しました';
    ELSE
        RAISE NOTICE 'daily_rewards.reward_type カラムは既に存在します';
    END IF;
END $$;

-- 4. 修正後のテーブル構造を確認
SELECT 
    '✅ 修正後 user_nfts 構造' as table_info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'user_nfts'
AND table_schema = 'public'
ORDER BY ordinal_position;
