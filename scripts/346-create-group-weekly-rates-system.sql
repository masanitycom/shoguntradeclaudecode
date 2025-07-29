-- グループ別週利システムの構築

-- 既存の関数を完全に削除
DROP FUNCTION IF EXISTS distribute_weekly_rate(numeric, date);
DROP FUNCTION IF EXISTS get_nft_group(numeric);

-- NFTグループ分類関数を作成
CREATE OR REPLACE FUNCTION get_nft_group(nft_price NUMERIC)
RETURNS TEXT AS $$
BEGIN
    CASE 
        WHEN nft_price = 125 THEN RETURN 'group_125';
        WHEN nft_price = 250 THEN RETURN 'group_250';
        WHEN nft_price = 375 THEN RETURN 'group_375';
        WHEN nft_price = 625 THEN RETURN 'group_625';
        WHEN nft_price = 1250 THEN RETURN 'group_1250';
        WHEN nft_price = 2500 THEN RETURN 'group_2500';
        WHEN nft_price = 7500 THEN RETURN 'group_7500';
        WHEN nft_price >= 10000 THEN RETURN 'group_high';
        ELSE RETURN 'group_other';
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- グループ別週利テーブルを作成
CREATE TABLE IF NOT EXISTS group_weekly_rates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    week_start_date DATE NOT NULL,
    nft_group TEXT NOT NULL,
    weekly_rate NUMERIC(10,4) NOT NULL DEFAULT 0,
    monday_rate NUMERIC(10,4) NOT NULL DEFAULT 0,
    tuesday_rate NUMERIC(10,4) NOT NULL DEFAULT 0,
    wednesday_rate NUMERIC(10,4) NOT NULL DEFAULT 0,
    thursday_rate NUMERIC(10,4) NOT NULL DEFAULT 0,
    friday_rate NUMERIC(10,4) NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(week_start_date, nft_group)
);

-- 今週のデフォルト週利を設定（2.6%を平日に均等配分）
INSERT INTO group_weekly_rates (
    week_start_date,
    nft_group,
    weekly_rate,
    monday_rate,
    tuesday_rate,
    wednesday_rate,
    thursday_rate,
    friday_rate
)
SELECT 
    DATE_TRUNC('week', CURRENT_DATE) as week_start_date,
    unnest(ARRAY[
        'group_125', 'group_250', 'group_375', 'group_625',
        'group_1250', 'group_2500', 'group_7500', 'group_high'
    ]) as nft_group,
    0.0260 as weekly_rate,
    0.0052 as monday_rate,
    0.0052 as tuesday_rate,
    0.0052 as wednesday_rate,
    0.0052 as thursday_rate,
    0.0052 as friday_rate
ON CONFLICT (week_start_date, nft_group) DO NOTHING;

-- グループ別週利設定確認
SELECT 
    '📊 グループ別週利設定確認' as status,
    nft_group,
    weekly_rate,
    monday_rate,
    tuesday_rate,
    wednesday_rate,
    thursday_rate,
    friday_rate
FROM group_weekly_rates
WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)
ORDER BY nft_group;

RAISE NOTICE 'グループ別週利システムの構築が完了しました';
