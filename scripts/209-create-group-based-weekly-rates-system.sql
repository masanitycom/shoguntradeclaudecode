-- 1. 日利上限グループテーブルを作成
CREATE TABLE IF NOT EXISTS daily_rate_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_name VARCHAR(50) NOT NULL UNIQUE,
    daily_rate_limit NUMERIC(5,4) NOT NULL, -- 0.0050 = 0.5%
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. グループ別週利設定テーブルを作成
CREATE TABLE IF NOT EXISTS group_weekly_rates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES daily_rate_groups(id) ON DELETE CASCADE,
    week_number INTEGER NOT NULL,
    week_start_date DATE NOT NULL,
    week_end_date DATE NOT NULL,
    weekly_rate NUMERIC(5,3) NOT NULL,
    monday_rate NUMERIC(5,3) DEFAULT 0,
    tuesday_rate NUMERIC(5,3) DEFAULT 0,
    wednesday_rate NUMERIC(5,3) DEFAULT 0,
    thursday_rate NUMERIC(5,3) DEFAULT 0,
    friday_rate NUMERIC(5,3) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    UNIQUE(group_id, week_number)
);

-- 3. インデックス作成
CREATE INDEX IF NOT EXISTS idx_group_weekly_rates_week ON group_weekly_rates(week_number);
CREATE INDEX IF NOT EXISTS idx_group_weekly_rates_date ON group_weekly_rates(week_start_date);
CREATE INDEX IF NOT EXISTS idx_group_weekly_rates_group ON group_weekly_rates(group_id);

-- 4. 日利上限グループを作成
INSERT INTO daily_rate_groups (group_name, daily_rate_limit, description) VALUES
('0.5%グループ', 0.005, 'SHOGUN NFT 100, 200の低リスクグループ'),
('1.0%グループ', 0.010, 'SHOGUN NFT 300, 500, 1000, 1200の中リスクグループ'),
('1.25%グループ', 0.0125, 'SHOGUN NFT 3000, 5000, 10000の高リスクグループ'),
('2.0%グループ', 0.020, 'SHOGUN NFT 30000, 100000の最高リスクグループ')
ON CONFLICT (group_name) DO NOTHING;

-- 5. NFTテーブルにgroup_idカラムを追加
ALTER TABLE nfts ADD COLUMN IF NOT EXISTS group_id UUID REFERENCES daily_rate_groups(id);

-- 6. 既存NFTをグループに自動分類
UPDATE nfts SET group_id = (
    SELECT id FROM daily_rate_groups 
    WHERE daily_rate_limit = nfts.daily_rate_limit
    AND NOT is_special
    LIMIT 1
) WHERE group_id IS NULL AND NOT is_special;

-- 特別NFTを1.0%グループに分類
UPDATE nfts SET group_id = (
    SELECT id FROM daily_rate_groups 
    WHERE group_name = '1.0%グループ'
    LIMIT 1
) WHERE group_id IS NULL AND is_special;

-- 7. グループ別NFT数を取得する関数
CREATE OR REPLACE FUNCTION get_daily_rate_groups_with_count()
RETURNS TABLE(
    id UUID,
    group_name VARCHAR,
    daily_rate_limit NUMERIC,
    description TEXT,
    nft_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        drg.id,
        drg.group_name,
        drg.daily_rate_limit,
        drg.description,
        COUNT(n.id) as nft_count
    FROM daily_rate_groups drg
    LEFT JOIN nfts n ON drg.id = n.group_id
    GROUP BY drg.id, drg.group_name, drg.daily_rate_limit, drg.description
    ORDER BY drg.daily_rate_limit;
END;
$$ LANGUAGE plpgsql;

-- 8. 週利に基づく日利計算関数
CREATE OR REPLACE FUNCTION calculate_weekly_daily_rewards(
    target_week INTEGER
) RETURNS TABLE(
    rewards_calculated INTEGER,
    total_amount NUMERIC
) AS $$
DECLARE
    week_start DATE;
    day_offset INTEGER;
    target_date DATE;
    rewards_count INTEGER := 0;
    total_reward_amount NUMERIC := 0;
    daily_rate NUMERIC;
BEGIN
    -- 週の開始日を計算（2025年1月6日を第1週の月曜日とする）
    week_start := '2025-01-06'::DATE + (target_week - 1) * 7;
    
    -- 月曜日から金曜日まで処理
    FOR day_offset IN 0..4 LOOP
        target_date := week_start + day_offset;
        
        -- その日の各グループの日利を取得して計算
        INSERT INTO daily_rewards (user_nft_id, user_id, reward_date, daily_rate, reward_amount, week_start_date, is_claimed)
        SELECT 
            un.id,
            un.user_id,
            target_date,
            CASE day_offset
                WHEN 0 THEN gwr.monday_rate / 100
                WHEN 1 THEN gwr.tuesday_rate / 100
                WHEN 2 THEN gwr.wednesday_rate / 100
                WHEN 3 THEN gwr.thursday_rate / 100
                WHEN 4 THEN gwr.friday_rate / 100
            END,
            un.current_investment * (
                CASE day_offset
                    WHEN 0 THEN gwr.monday_rate / 100
                    WHEN 1 THEN gwr.tuesday_rate / 100
                    WHEN 2 THEN gwr.wednesday_rate / 100
                    WHEN 3 THEN gwr.thursday_rate / 100
                    WHEN 4 THEN gwr.friday_rate / 100
                END
            ),
            week_start,
            false
        FROM user_nfts un
        JOIN nfts n ON un.nft_id = n.id
        JOIN group_weekly_rates gwr ON n.group_id = gwr.group_id
        WHERE un.is_active = true
        AND gwr.week_number = target_week
        AND NOT EXISTS (
            SELECT 1 FROM daily_rewards dr 
            WHERE dr.user_nft_id = un.id AND dr.reward_date = target_date
        )
        -- 300%上限チェック
        AND (un.total_earned + un.current_investment * (
            CASE day_offset
                WHEN 0 THEN gwr.monday_rate / 100
                WHEN 1 THEN gwr.tuesday_rate / 100
                WHEN 2 THEN gwr.wednesday_rate / 100
                WHEN 3 THEN gwr.thursday_rate / 100
                WHEN 4 THEN gwr.friday_rate / 100
            END
        )) <= un.max_earning;
        
        GET DIAGNOSTICS rewards_count = ROW_COUNT;
        
        SELECT COALESCE(SUM(reward_amount), 0) INTO daily_rate
        FROM daily_rewards 
        WHERE reward_date = target_date;
        
        total_reward_amount := total_reward_amount + daily_rate;
    END LOOP;
    
    RETURN QUERY SELECT rewards_count, total_reward_amount;
END;
$$ LANGUAGE plpgsql;

-- 9. 確認用クエリ
SELECT 'Group-based weekly rate system created successfully' as status;

-- グループ確認
SELECT * FROM get_daily_rate_groups_with_count();
