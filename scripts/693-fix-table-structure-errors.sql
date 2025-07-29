-- テーブル構造エラーの修正

-- 1. nftsテーブルの構造を確認
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'nfts'
ORDER BY ordinal_position;

-- 2. daily_rate_groupsテーブルの構造を確認
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'daily_rate_groups'
ORDER BY ordinal_position;

-- 3. NFTとグループの関連を確認
-- NFTの日利上限に基づいてグループを決定する方法を使用

-- 4. 不足しているカラムがあれば追加
DO $$
BEGIN
    -- nftsテーブルにdaily_rate_group_idカラムが存在しない場合は追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'nfts' 
        AND column_name = 'daily_rate_group_id'
    ) THEN
        ALTER TABLE nfts ADD COLUMN daily_rate_group_id UUID;
        RAISE NOTICE 'daily_rate_group_idカラムを追加しました';
        
        -- 既存のNFTにグループIDを設定
        UPDATE nfts SET daily_rate_group_id = (
            SELECT drg.id 
            FROM daily_rate_groups drg 
            WHERE drg.daily_rate_limit = nfts.daily_rate_limit
            LIMIT 1
        );
        
        RAISE NOTICE 'NFTにグループIDを設定しました';
    ELSE
        RAISE NOTICE 'daily_rate_group_idカラムは既に存在します';
    END IF;
END $$;

-- 5. 外部キー制約を追加
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'nfts' 
        AND constraint_name = 'fk_nfts_daily_rate_group'
    ) THEN
        ALTER TABLE nfts 
        ADD CONSTRAINT fk_nfts_daily_rate_group 
        FOREIGN KEY (daily_rate_group_id) REFERENCES daily_rate_groups(id);
        
        RAISE NOTICE '外部キー制約を追加しました';
    ELSE
        RAISE NOTICE '外部キー制約は既に存在します';
    END IF;
END $$;
