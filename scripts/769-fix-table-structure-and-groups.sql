-- テーブル構造とグループマッピングを修正

-- 1. daily_rate_groups テーブル構造を確認・修正
DO $$
BEGIN
    -- updated_at カラムが存在しない場合は追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'daily_rate_groups' 
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE daily_rate_groups ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    -- created_at カラムが存在しない場合は追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'daily_rate_groups' 
        AND column_name = 'created_at'
    ) THEN
        ALTER TABLE daily_rate_groups ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- 2. 既存のグループデータをクリア
DELETE FROM group_weekly_rates;
DELETE FROM daily_rate_groups;

-- 3. 正しいグループ定義を作成
INSERT INTO daily_rate_groups (group_name, daily_rate_limit, created_at, updated_at) VALUES
('0.5%グループ', 0.5, NOW(), NOW()),
('1.0%グループ', 1.0, NOW(), NOW()),
('1.25%グループ', 1.25, NOW(), NOW()),
('1.5%グループ', 1.5, NOW(), NOW()),
('1.75%グループ', 1.75, NOW(), NOW()),
('2.0%グループ', 2.0, NOW(), NOW());

-- 4. 2025-02-10週の週利設定
INSERT INTO group_weekly_rates (
    week_start_date,
    group_name,
    weekly_rate,
    monday_rate,
    tuesday_rate,
    wednesday_rate,
    thursday_rate,
    friday_rate,
    distribution_method,
    created_at,
    updated_at
) VALUES
('2025-02-10', '0.5%グループ', 0.015, 0.003, 0.003, 0.003, 0.003, 0.003, 'manual', NOW(), NOW()),
('2025-02-10', '1.0%グループ', 0.020, 0.004, 0.004, 0.004, 0.004, 0.004, 'manual', NOW(), NOW()),
('2025-02-10', '1.25%グループ', 0.023, 0.0046, 0.0046, 0.0046, 0.0046, 0.0046, 'manual', NOW(), NOW()),
('2025-02-10', '1.5%グループ', 0.026, 0.0052, 0.0052, 0.0052, 0.0052, 0.0052, 'manual', NOW(), NOW()),
('2025-02-10', '1.75%グループ', 0.029, 0.0058, 0.0058, 0.0058, 0.0058, 0.0058, 'manual', NOW(), NOW()),
('2025-02-10', '2.0%グループ', 0.032, 0.0064, 0.0064, 0.0064, 0.0064, 0.0064, 'manual', NOW(), NOW());

-- 5. 2025-02-17週の週利設定
INSERT INTO group_weekly_rates (
    week_start_date,
    group_name,
    weekly_rate,
    monday_rate,
    tuesday_rate,
    wednesday_rate,
    thursday_rate,
    friday_rate,
    distribution_method,
    created_at,
    updated_at
) VALUES
('2025-02-17', '0.5%グループ', 0.015, 0.003, 0.003, 0.003, 0.003, 0.003, 'manual', NOW(), NOW()),
('2025-02-17', '1.0%グループ', 0.020, 0.004, 0.004, 0.004, 0.004, 0.004, 'manual', NOW(), NOW()),
('2025-02-17', '1.25%グループ', 0.023, 0.0046, 0.0046, 0.0046, 0.0046, 0.0046, 'manual', NOW(), NOW()),
('2025-02-17', '1.5%グループ', 0.026, 0.0052, 0.0052, 0.0052, 0.0052, 0.0052, 'manual', NOW(), NOW()),
('2025-02-17', '1.75%グループ', 0.029, 0.0058, 0.0058, 0.0058, 0.0058, 0.0058, 'manual', NOW(), NOW()),
('2025-02-17', '2.0%グループ', 0.032, 0.0064, 0.0064, 0.0064, 0.0064, 0.0064, 'manual', NOW(), NOW());

-- 6. 作成結果を確認
SELECT 
    '=== グループ作成結果 ===' as section,
    group_name,
    daily_rate_limit
FROM daily_rate_groups
ORDER BY daily_rate_limit;

SELECT 
    '=== 週利設定結果 ===' as section,
    week_start_date,
    group_name,
    (weekly_rate * 100)::numeric(5,2) as weekly_rate_percent,
    (monday_rate * 100)::numeric(5,3) as monday_rate_percent
FROM group_weekly_rates
ORDER BY week_start_date, group_name;

SELECT '✅ テーブル構造とグループ修正完了' as status;
