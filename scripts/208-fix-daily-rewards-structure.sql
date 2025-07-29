-- daily_rewardsテーブルにbonus_amountカラムを追加

-- 1. daily_rewardsテーブルの現在の構造を確認
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
ORDER BY ordinal_position;

-- 2. bonus_amountカラムが存在しない場合は追加
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'daily_rewards' 
        AND column_name = 'bonus_amount'
    ) THEN
        ALTER TABLE daily_rewards 
        ADD COLUMN bonus_amount NUMERIC(10,2) DEFAULT 0.00;
        
        RAISE NOTICE 'bonus_amountカラムを追加しました';
    ELSE
        RAISE NOTICE 'bonus_amountカラムは既に存在します';
    END IF;
END $$;

-- 3. 既存のレコードにデフォルト値を設定
UPDATE daily_rewards 
SET bonus_amount = 0.00 
WHERE bonus_amount IS NULL;

-- 4. user_idカラムが存在しない場合は追加
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'daily_rewards' 
        AND column_name = 'user_id'
    ) THEN
        ALTER TABLE daily_rewards 
        ADD COLUMN user_id UUID;
        
        -- user_nftsからuser_idを取得して設定
        UPDATE daily_rewards dr
        SET user_id = un.user_id
        FROM user_nfts un
        WHERE dr.user_nft_id = un.id;
        
        RAISE NOTICE 'user_idカラムを追加しました';
    ELSE
        RAISE NOTICE 'user_idカラムは既に存在します';
    END IF;
END $$;

-- 5. 更新された構造を確認
SELECT 'Updated daily_rewards structure' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
ORDER BY ordinal_position;
