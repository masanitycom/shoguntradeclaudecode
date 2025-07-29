-- mlm_ranksテーブルの構造を修正し、不足カラムを追加

-- 1. mlm_ranksテーブルに不足しているカラムを安全に追加
DO $$
BEGIN
    -- required_nft_investmentカラムを追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'mlm_ranks' 
        AND column_name = 'required_nft_investment'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE mlm_ranks ADD COLUMN required_nft_investment DECIMAL(15,2) DEFAULT 1000;
        RAISE NOTICE 'mlm_ranksテーブルにrequired_nft_investmentカラムを追加しました';
    ELSE
        RAISE NOTICE 'required_nft_investmentカラムは既に存在します';
    END IF;

    -- required_organization_sizeカラムを追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'mlm_ranks' 
        AND column_name = 'required_organization_size'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE mlm_ranks ADD COLUMN required_organization_size INTEGER DEFAULT 0;
        RAISE NOTICE 'mlm_ranksテーブルにrequired_organization_sizeカラムを追加しました';
    ELSE
        RAISE NOTICE 'required_organization_sizeカラムは既に存在します';
    END IF;

    -- max_line_sizeカラムを追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'mlm_ranks' 
        AND column_name = 'max_line_size'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE mlm_ranks ADD COLUMN max_line_size INTEGER DEFAULT 0;
        RAISE NOTICE 'mlm_ranksテーブルにmax_line_sizeカラムを追加しました';
    ELSE
        RAISE NOTICE 'max_line_sizeカラムは既に存在します';
    END IF;

    -- other_lines_volumeカラムを追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'mlm_ranks' 
        AND column_name = 'other_lines_volume'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE mlm_ranks ADD COLUMN other_lines_volume INTEGER DEFAULT 0;
        RAISE NOTICE 'mlm_ranksテーブルにother_lines_volumeカラムを追加しました';
    ELSE
        RAISE NOTICE 'other_lines_volumeカラムは既に存在します';
    END IF;

    -- distribution_rateカラムを追加（まだ存在しない場合）
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'mlm_ranks' 
        AND column_name = 'distribution_rate'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE mlm_ranks ADD COLUMN distribution_rate DECIMAL(5,4) DEFAULT 0;
        RAISE NOTICE 'mlm_ranksテーブルにdistribution_rateカラムを追加しました';
    ELSE
        RAISE NOTICE 'distribution_rateカラムは既に存在します';
    END IF;

    -- bonus_rateカラムを追加（まだ存在しない場合）
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'mlm_ranks' 
        AND column_name = 'bonus_rate'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE mlm_ranks ADD COLUMN bonus_rate DECIMAL(5,4) DEFAULT 0;
        RAISE NOTICE 'mlm_ranksテーブルにbonus_rateカラムを追加しました';
    ELSE
        RAISE NOTICE 'bonus_rateカラムは既に存在します';
    END IF;
END $$;

-- 2. MLMランクの完全なデータを設定
DELETE FROM mlm_ranks; -- 既存データをクリア

INSERT INTO mlm_ranks (
    rank_level,
    rank_name,
    required_nft_investment,
    required_organization_size,
    max_line_size,
    other_lines_volume,
    distribution_rate,
    bonus_rate,
    created_at
) VALUES 
(0, 'なし', 0, 0, 0, 0, 0.0000, 0.0000, NOW()),
(1, '足軽', 1000, 1000, 0, 0, 0.4500, 0.4500, NOW()),
(2, '武将', 1000, 3000, 1500, 1500, 0.2500, 0.2500, NOW()),
(3, '代官', 1000, 5000, 2500, 2500, 0.1000, 0.1000, NOW()),
(4, '奉行', 1000, 10000, 5000, 5000, 0.0600, 0.0600, NOW()),
(5, '老中', 1000, 50000, 25000, 25000, 0.0500, 0.0500, NOW()),
(6, '大老', 1000, 100000, 50000, 50000, 0.0400, 0.0400, NOW()),
(7, '大名', 1000, 300000, 150000, 150000, 0.0300, 0.0300, NOW()),
(8, '将軍', 1000, 600000, 500000, 100000, 0.0200, 0.0200, NOW());

-- 3. 結果確認
SELECT 
    '✅ MLMランク設定完了' as status,
    rank_level,
    rank_name,
    required_nft_investment,
    required_organization_size,
    max_line_size,
    other_lines_volume,
    distribution_rate * 100 as distribution_percent,
    bonus_rate * 100 as bonus_percent
FROM mlm_ranks 
ORDER BY rank_level;

SELECT '✅ MLMランクテーブル構造修正完了' as final_status;
