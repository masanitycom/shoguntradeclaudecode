-- 不足しているカラムを安全に追加

-- usersテーブルに不足しているカラムを追加
DO $$
BEGIN
    -- current_rankカラムを追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'current_rank'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE users ADD COLUMN current_rank VARCHAR(50);
        RAISE NOTICE 'usersテーブルにcurrent_rankカラムを追加しました';
    ELSE
        RAISE NOTICE 'current_rankカラムは既に存在します';
    END IF;

    -- is_activeカラムを追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'is_active'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE users ADD COLUMN is_active BOOLEAN DEFAULT true;
        RAISE NOTICE 'usersテーブルにis_activeカラムを追加しました';
    ELSE
        RAISE NOTICE 'is_activeカラムは既に存在します';
    END IF;

    -- total_earnedカラムを追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'total_earned'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE users ADD COLUMN total_earned DECIMAL(15,2) DEFAULT 0;
        RAISE NOTICE 'usersテーブルにtotal_earnedカラムを追加しました';
    ELSE
        RAISE NOTICE 'total_earnedカラムは既に存在します';
    END IF;

    -- pending_rewardsカラムを追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'pending_rewards'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE users ADD COLUMN pending_rewards DECIMAL(15,2) DEFAULT 0;
        RAISE NOTICE 'usersテーブルにpending_rewardsカラムを追加しました';
    ELSE
        RAISE NOTICE 'pending_rewardsカラムは既に存在します';
    END IF;

    -- current_rank_levelカラムを追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'current_rank_level'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE users ADD COLUMN current_rank_level INTEGER DEFAULT 0;
        RAISE NOTICE 'usersテーブルにcurrent_rank_levelカラムを追加しました';
    ELSE
        RAISE NOTICE 'current_rank_levelカラムは既に存在します';
    END IF;
END $$;

-- mlm_ranksテーブルに不足しているカラムを追加
DO $$
BEGIN
    -- distribution_rateカラムを追加
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

    -- bonus_rateカラムを追加（既存の場合はスキップ）
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

-- group_weekly_ratesテーブルに不足しているカラムを追加
DO $$
BEGIN
    -- distribution_methodカラムを追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'group_weekly_rates' 
        AND column_name = 'distribution_method'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE group_weekly_rates ADD COLUMN distribution_method VARCHAR(50) DEFAULT 'RANDOM_SYNCHRONIZED';
        RAISE NOTICE 'group_weekly_ratesテーブルにdistribution_methodカラムを追加しました';
    ELSE
        RAISE NOTICE 'distribution_methodカラムは既に存在します';
    END IF;

    -- week_numberカラムを追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'group_weekly_rates' 
        AND column_name = 'week_number'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE group_weekly_rates ADD COLUMN week_number INTEGER;
        RAISE NOTICE 'group_weekly_ratesテーブルにweek_numberカラムを追加しました';
    ELSE
        RAISE NOTICE 'week_numberカラムは既に存在します';
    END IF;
END $$;

-- daily_rewardsテーブルに不足しているカラムを追加
DO $$
BEGIN
    -- week_start_dateカラムを追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'daily_rewards' 
        AND column_name = 'week_start_date'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE daily_rewards ADD COLUMN week_start_date DATE;
        RAISE NOTICE 'daily_rewardsテーブルにweek_start_dateカラムを追加しました';
    ELSE
        RAISE NOTICE 'week_start_dateカラムは既に存在します';
    END IF;

    -- updated_atカラムを追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'daily_rewards' 
        AND column_name = 'updated_at'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE daily_rewards ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'daily_rewardsテーブルにupdated_atカラムを追加しました';
    ELSE
        RAISE NOTICE 'updated_atカラムは既に存在します';
    END IF;
END $$;

-- user_nftsテーブルに不足しているカラムを追加
DO $$
BEGIN
    -- total_earnedカラムを追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_nfts' 
        AND column_name = 'total_earned'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE user_nfts ADD COLUMN total_earned DECIMAL(15,2) DEFAULT 0;
        RAISE NOTICE 'user_nftsテーブルにtotal_earnedカラムを追加しました';
    ELSE
        RAISE NOTICE 'total_earnedカラムは既に存在します';
    END IF;

    -- updated_atカラムを追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_nfts' 
        AND column_name = 'updated_at'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE user_nfts ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'user_nftsテーブルにupdated_atカラムを追加しました';
    ELSE
        RAISE NOTICE 'updated_atカラムは既に存在します';
    END IF;
END $$;

-- 初期データを設定
UPDATE users SET 
    is_active = true,
    total_earned = 0,
    pending_rewards = 0,
    current_rank_level = 0,
    current_rank = 'なし'
WHERE is_active IS NULL OR current_rank IS NULL;

-- mlm_ranksテーブルのdistribution_rateを更新
UPDATE mlm_ranks SET 
    distribution_rate = CASE 
        WHEN rank_level = 1 THEN 0.45  -- 45%
        WHEN rank_level = 2 THEN 0.25  -- 25%
        WHEN rank_level = 3 THEN 0.10  -- 10%
        WHEN rank_level = 4 THEN 0.06  -- 6%
        WHEN rank_level = 5 THEN 0.05  -- 5%
        WHEN rank_level = 6 THEN 0.04  -- 4%
        WHEN rank_level = 7 THEN 0.03  -- 3%
        WHEN rank_level = 8 THEN 0.02  -- 2%
        ELSE 0
    END,
    bonus_rate = CASE 
        WHEN rank_level = 1 THEN 0.45  -- 45%
        WHEN rank_level = 2 THEN 0.25  -- 25%
        WHEN rank_level = 3 THEN 0.10  -- 10%
        WHEN rank_level = 4 THEN 0.06  -- 6%
        WHEN rank_level = 5 THEN 0.05  -- 5%
        WHEN rank_level = 6 THEN 0.04  -- 4%
        WHEN rank_level = 7 THEN 0.03  -- 3%
        WHEN rank_level = 8 THEN 0.02  -- 2%
        ELSE 0
    END
WHERE distribution_rate IS NULL OR distribution_rate = 0;

SELECT '✅ 不足カラムの追加と初期データ設定完了' as final_status;
