-- 週利管理システムのテーブル関係修正

-- 1. daily_rate_groupsテーブルを作成（存在しない場合）
CREATE TABLE IF NOT EXISTS daily_rate_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_name VARCHAR(50) UNIQUE NOT NULL,
    daily_rate_limit DECIMAL(5,4) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. daily_rate_groupsにデータを挿入
INSERT INTO daily_rate_groups (group_name, daily_rate_limit, description) VALUES
    ('group_125', 0.0050, '$125 NFTグループ - 日利上限0.5%'),
    ('group_250', 0.0050, '$250 NFTグループ - 日利上限0.5%'),
    ('group_375', 0.0050, '$375 NFTグループ - 日利上限0.5%'),
    ('group_625', 0.0050, '$625 NFTグループ - 日利上限0.5%'),
    ('group_1250', 0.0100, '$1250 NFTグループ - 日利上限1.0%'),
    ('group_2500', 0.0100, '$2500 NFTグループ - 日利上限1.0%'),
    ('group_7500', 0.0125, '$7500 NFTグループ - 日利上限1.25%'),
    ('group_high', 0.0200, '高額NFTグループ - 日利上限2.0%')
ON CONFLICT (group_name) DO UPDATE SET
    daily_rate_limit = EXCLUDED.daily_rate_limit,
    description = EXCLUDED.description;

-- 3. group_weekly_ratesテーブルを修正（group_idカラムを追加）
DO $$
BEGIN
    -- group_idカラムが存在しない場合は追加
    IF NOT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_name = 'group_weekly_rates' 
        AND column_name = 'group_id'
    ) THEN
        ALTER TABLE group_weekly_rates ADD COLUMN group_id UUID;
    END IF;
END $$;

-- 4. 外部キー制約を追加
DO $$
BEGIN
    -- 外部キー制約が存在しない場合は追加
    IF NOT EXISTS (
        SELECT FROM information_schema.table_constraints 
        WHERE table_name = 'group_weekly_rates' 
        AND constraint_name = 'fk_group_weekly_rates_group_id'
    ) THEN
        ALTER TABLE group_weekly_rates 
        ADD CONSTRAINT fk_group_weekly_rates_group_id 
        FOREIGN KEY (group_id) REFERENCES daily_rate_groups(id);
    END IF;
END $$;

-- 5. 既存のgroup_weekly_ratesデータのgroup_idを更新
UPDATE group_weekly_rates 
SET group_id = drg.id
FROM daily_rate_groups drg
WHERE group_weekly_rates.nft_group = drg.group_name
AND group_weekly_rates.group_id IS NULL;

-- 6. RLSポリシーを設定
ALTER TABLE daily_rate_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_weekly_rates ENABLE ROW LEVEL SECURITY;

-- 管理者のみアクセス可能なポリシー
DROP POLICY IF EXISTS "Admin only access daily_rate_groups" ON daily_rate_groups;
CREATE POLICY "Admin only access daily_rate_groups" ON daily_rate_groups
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.is_admin = true
        )
    );

DROP POLICY IF EXISTS "Admin only access group_weekly_rates" ON group_weekly_rates;
CREATE POLICY "Admin only access group_weekly_rates" ON group_weekly_rates
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.is_admin = true
        )
    );

-- 7. インデックスを作成
CREATE INDEX IF NOT EXISTS idx_group_weekly_rates_group_id 
ON group_weekly_rates(group_id);

CREATE INDEX IF NOT EXISTS idx_group_weekly_rates_week_start 
ON group_weekly_rates(week_start_date);

CREATE INDEX IF NOT EXISTS idx_daily_rate_groups_group_name 
ON daily_rate_groups(group_name);

-- 8. 結果確認
SELECT 
    '📊 テーブル関係修正結果' as status,
    gwr.nft_group,
    drg.group_name,
    drg.daily_rate_limit,
    gwr.weekly_rate,
    gwr.week_start_date
FROM group_weekly_rates gwr
LEFT JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)
ORDER BY drg.group_name;
