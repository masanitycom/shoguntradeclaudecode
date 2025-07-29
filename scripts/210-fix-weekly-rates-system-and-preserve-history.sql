-- 1. 既存のテーブル構造を確認し、必要に応じて作成
CREATE TABLE IF NOT EXISTS daily_rate_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_name VARCHAR(50) NOT NULL UNIQUE,
    daily_rate_limit NUMERIC(5,4) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

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

-- 2. 日利上限グループを作成（既存の場合は無視）
INSERT INTO daily_rate_groups (group_name, daily_rate_limit, description) VALUES
('0.5%グループ', 0.005, 'SHOGUN NFT 100, 200の低リスクグループ'),
('1.0%グループ', 0.010, 'SHOGUN NFT 300, 500, 1000, 1200の中リスクグループ'),
('1.25%グループ', 0.0125, 'SHOGUN NFT 3000, 5000, 10000の高リスクグループ'),
('2.0%グループ', 0.020, 'SHOGUN NFT 30000, 100000の最高リスクグループ')
ON CONFLICT (group_name) DO NOTHING;

-- 3. NFTテーブルにgroup_idカラムを追加（既存の場合は無視）
ALTER TABLE nfts ADD COLUMN IF NOT EXISTS group_id UUID REFERENCES daily_rate_groups(id);

-- 4. 既存NFTをグループに自動分類
UPDATE nfts SET group_id = (
    CASE 
        WHEN daily_rate_limit = 0.005 THEN (SELECT id FROM daily_rate_groups WHERE group_name = '0.5%グループ')
        WHEN daily_rate_limit = 0.010 THEN (SELECT id FROM daily_rate_groups WHERE group_name = '1.0%グループ')
        WHEN daily_rate_limit = 0.0125 THEN (SELECT id FROM daily_rate_groups WHERE group_name = '1.25%グループ')
        WHEN daily_rate_limit = 0.020 THEN (SELECT id FROM daily_rate_groups WHERE group_name = '2.0%グループ')
        ELSE (SELECT id FROM daily_rate_groups WHERE group_name = '1.0%グループ')
    END
) WHERE group_id IS NULL;

-- 5. インデックス作成
CREATE INDEX IF NOT EXISTS idx_group_weekly_rates_week ON group_weekly_rates(week_number);
CREATE INDEX IF NOT EXISTS idx_group_weekly_rates_date ON group_weekly_rates(week_start_date);
CREATE INDEX IF NOT EXISTS idx_group_weekly_rates_group ON group_weekly_rates(group_id);
CREATE INDEX IF NOT EXISTS idx_nfts_group_id ON nfts(group_id);

-- 6. 週利に基づく日利計算関数を修正
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

-- 7. 過去の週利データを新システムに移行（既存データを保持）
-- 既存のnft_weekly_ratesテーブルのデータはそのまま保持し、履歴として表示

-- 8. 確認用クエリ
SELECT 'Weekly rates system fixed and history preserved' as status;

-- グループ確認
SELECT 
    drg.group_name,
    drg.daily_rate_limit,
    drg.description,
    COUNT(n.id) as nft_count
FROM daily_rate_groups drg
LEFT JOIN nfts n ON drg.id = n.group_id
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit, drg.description
ORDER BY drg.daily_rate_limit;

-- 過去の週利履歴確認
SELECT 
    COUNT(*) as total_historical_records,
    MIN(week_number) as earliest_week,
    MAX(week_number) as latest_week
FROM nft_weekly_rates;
