-- 1. 日利上限グループテーブルを作成
CREATE TABLE IF NOT EXISTS daily_rate_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_name VARCHAR(50) NOT NULL UNIQUE,
    daily_rate_limit NUMERIC(5,3) NOT NULL,
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

-- 4. 日利上限グループを作成（CSVデータから分析）
INSERT INTO daily_rate_groups (group_name, daily_rate_limit, description) VALUES
('0.5%グループ', 0.005, 'SHOGUN NFT 100, 200の低リスクグループ'),
('1.0%グループ', 0.010, 'SHOGUN NFT 300, 500, 1000, 1200, 3000, 5000の中リスクグループ'),
('1.25%グループ', 0.0125, 'SHOGUN NFT 10000の高リスクグループ'),
('特別NFTグループ', 0.010, '特別NFT（管理者付与）のグループ'),
('プレミアムグループ', 0.015, 'SHOGUN NFT 30000の最高リスクグループ'),
('ウルトラグループ', 0.020, 'SHOGUN NFT 100000の超高リスクグループ')
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

-- 特別NFTを特別グループに分類
UPDATE nfts SET group_id = (
    SELECT id FROM daily_rate_groups 
    WHERE group_name = '特別NFTグループ'
    LIMIT 1
) WHERE group_id IS NULL AND is_special;

-- 7. CSVデータから週利設定をインポートする関数
CREATE OR REPLACE FUNCTION import_csv_weekly_rates()
RETURNS TABLE(
    week_imported INTEGER,
    rate_imported NUMERIC,
    groups_affected INTEGER
) AS $$
DECLARE
    week_data RECORD;
    group_record RECORD;
    week_start DATE;
    week_end DATE;
BEGIN
    -- 10週目から18週目のデータをインポート（CSVの実データ部分）
    FOR week_data IN 
        SELECT * FROM (VALUES
            (10, 1.46), (11, 1.37), (12, 1.51), (13, 0.85), (14, 1.49),
            (15, 1.89), (16, 1.76), (17, 2.02), (18, 2.23)
        ) AS weeks(week_num, rate)
    LOOP
        -- 週の開始日と終了日を計算（仮定：2025年1月6日を第1週の月曜日とする）
        week_start := '2025-01-06'::DATE + (week_data.week_num - 1) * 7;
        week_end := week_start + 4; -- 金曜日まで
        
        -- 各グループに同じ週利を設定
        FOR group_record IN SELECT id FROM daily_rate_groups
        LOOP
            INSERT INTO group_weekly_rates (
                group_id, week_number, week_start_date, week_end_date, weekly_rate,
                monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate
            ) 
            SELECT 
                group_record.id,
                week_data.week_num,
                week_start,
                week_end,
                week_data.rate,
                -- 週利を5日間にランダム配分
                ROUND((week_data.rate * (0.15 + random() * 0.25))::NUMERIC, 3),
                ROUND((week_data.rate * (0.15 + random() * 0.25))::NUMERIC, 3),
                ROUND((week_data.rate * (0.15 + random() * 0.25))::NUMERIC, 3),
                ROUND((week_data.rate * (0.15 + random() * 0.25))::NUMERIC, 3),
                ROUND((week_data.rate * (0.15 + random() * 0.25))::NUMERIC, 3)
            ON CONFLICT (group_id, week_number) DO UPDATE SET
                weekly_rate = EXCLUDED.weekly_rate,
                monday_rate = EXCLUDED.monday_rate,
                tuesday_rate = EXCLUDED.tuesday_rate,
                wednesday_rate = EXCLUDED.wednesday_rate,
                thursday_rate = EXCLUDED.thursday_rate,
                friday_rate = EXCLUDED.friday_rate;
        END LOOP;
        
        RETURN QUERY SELECT week_data.week_num, week_data.rate, (SELECT COUNT(*)::INTEGER FROM daily_rate_groups);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 8. 過去の日利計算を行う関数
CREATE OR REPLACE FUNCTION calculate_historical_daily_rewards(
    start_week INTEGER DEFAULT 10,
    end_week INTEGER DEFAULT 18
) RETURNS TABLE(
    week_number INTEGER,
    total_rewards_calculated INTEGER,
    total_amount NUMERIC
) AS $$
DECLARE
    week_num INTEGER;
    day_offset INTEGER;
    target_date DATE;
    week_start DATE;
    daily_rate NUMERIC;
    rewards_count INTEGER;
    total_reward_amount NUMERIC;
BEGIN
    FOR week_num IN start_week..end_week LOOP
        week_start := '2025-01-06'::DATE + (week_num - 1) * 7;
        rewards_count := 0;
        total_reward_amount := 0;
        
        -- 月曜日から金曜日まで処理
        FOR day_offset IN 0..4 LOOP
            target_date := week_start + day_offset;
            
            -- その日の各グループの日利を取得して計算
            INSERT INTO daily_rewards (user_nft_id, reward_date, daily_rate, reward_amount, week_start_date, is_claimed)
            SELECT 
                un.id,
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
            AND gwr.week_number = week_num
            AND NOT EXISTS (
                SELECT 1 FROM daily_rewards dr 
                WHERE dr.user_nft_id = un.id AND dr.reward_date = target_date
            );
            
            GET DIAGNOSTICS rewards_count = ROW_COUNT;
            
            SELECT COALESCE(SUM(reward_amount), 0) INTO daily_rate
            FROM daily_rewards 
            WHERE reward_date = target_date;
            
            total_reward_amount := total_reward_amount + daily_rate;
        END LOOP;
        
        RETURN QUERY SELECT week_num, rewards_count, total_reward_amount;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 9. 確認用クエリ
SELECT 'Group-based weekly rate system created successfully' as status;

-- グループ確認
SELECT 
    drg.group_name,
    drg.daily_rate_limit,
    COUNT(n.id) as nft_count
FROM daily_rate_groups drg
LEFT JOIN nfts n ON drg.id = n.group_id
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;
