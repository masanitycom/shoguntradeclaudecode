-- 週利グループを修正

-- 1. 既存のdaily_rate_groupsテーブルを削除して再作成
DROP TABLE IF EXISTS daily_rate_groups CASCADE;

CREATE TABLE daily_rate_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_name VARCHAR(50) NOT NULL UNIQUE,
    daily_rate_limit NUMERIC(5,4) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. シンプルなグループを作成
INSERT INTO daily_rate_groups (group_name, daily_rate_limit, description) VALUES
('0.5%グループ', 0.005, '日利上限0.5%'),
('1.0%グループ', 0.010, '日利上限1.0%'),
('1.25%グループ', 0.0125, '日利上限1.25%'),
('1.5%グループ', 0.015, '日利上限1.5%'),
('1.75%グループ', 0.0175, '日利上限1.75%'),
('2.0%グループ', 0.020, '日利上限2.0%');

-- 3. group_weekly_ratesテーブルの構造を確認・修正
ALTER TABLE group_weekly_rates DROP CONSTRAINT IF EXISTS group_weekly_rates_group_id_fkey;
ALTER TABLE group_weekly_rates DROP COLUMN IF EXISTS group_id;
ALTER TABLE group_weekly_rates DROP COLUMN IF EXISTS nft_group;

-- group_nameカラムがない場合は追加
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'group_weekly_rates' AND column_name = 'group_name') THEN
        ALTER TABLE group_weekly_rates ADD COLUMN group_name VARCHAR(50);
    END IF;
END $$;

-- 4. 外部キー制約を追加
ALTER TABLE group_weekly_rates 
ADD CONSTRAINT fk_group_weekly_rates_group_name 
FOREIGN KEY (group_name) REFERENCES daily_rate_groups(group_name);

-- 5. NFTsテーブルのdaily_rate_limitを更新
UPDATE nfts SET daily_rate_limit = 0.005 WHERE price <= 625;
UPDATE nfts SET daily_rate_limit = 0.010 WHERE price > 625 AND price <= 2500;
UPDATE nfts SET daily_rate_limit = 0.0125 WHERE price > 2500 AND price <= 10000;
UPDATE nfts SET daily_rate_limit = 0.015 WHERE price > 10000 AND price <= 30000;
UPDATE nfts SET daily_rate_limit = 0.0175 WHERE price > 30000 AND price <= 50000;
UPDATE nfts SET daily_rate_limit = 0.020 WHERE price > 50000;

-- 6. get_nft_group関数を再作成
DROP FUNCTION IF EXISTS get_nft_group(numeric);

CREATE OR REPLACE FUNCTION get_nft_group(nft_price NUMERIC)
RETURNS VARCHAR(50) AS $$
BEGIN
    IF nft_price <= 625 THEN
        RETURN '0.5%グループ';
    ELSIF nft_price <= 2500 THEN
        RETURN '1.0%グループ';
    ELSIF nft_price <= 10000 THEN
        RETURN '1.25%グループ';
    ELSIF nft_price <= 30000 THEN
        RETURN '1.5%グループ';
    ELSIF nft_price <= 50000 THEN
        RETURN '1.75%グループ';
    ELSE
        RETURN '2.0%グループ';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 7. 確認
SELECT 
    '📊 週利グループ確認' as status,
    group_name,
    ROUND(daily_rate_limit * 100, 2) || '%' as daily_rate_limit,
    (SELECT COUNT(*) FROM nfts WHERE daily_rate_limit = drg.daily_rate_limit AND is_active = true) as nft_count
FROM daily_rate_groups drg
ORDER BY daily_rate_limit;
