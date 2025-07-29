-- 週利設定システムの完全作成

-- 1. 現在のテーブル構造確認
DO $$
BEGIN
    RAISE NOTICE '📊 現在のgroup_weekly_ratesテーブル構造確認';
END $$;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates' 
ORDER BY ordinal_position;

-- 2. 必要な制約を安全に追加
DO $$
BEGIN
    -- 一意制約が存在しない場合のみ追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'group_weekly_rates' 
        AND constraint_type = 'UNIQUE'
        AND constraint_name = 'group_weekly_rates_unique_week'
    ) THEN
        ALTER TABLE group_weekly_rates 
        ADD CONSTRAINT group_weekly_rates_unique_week 
        UNIQUE (daily_rate_limit, week_start_date);
        RAISE NOTICE '✅ 一意制約を追加しました';
    ELSE
        RAISE NOTICE '✅ 一意制約は既に存在します';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '⚠️ 制約追加でエラー: %', SQLERRM;
END $$;

-- 3. 既存の週利設定を削除（今週分のみ）
DELETE FROM group_weekly_rates 
WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE);

-- 4. 5つのグループ全てに週利設定を作成
INSERT INTO group_weekly_rates (
    daily_rate_limit,
    week_start_date,
    weekly_rate,
    monday_rate,
    tuesday_rate,
    wednesday_rate,
    thursday_rate,
    friday_rate,
    created_at,
    updated_at
) VALUES 
-- 0.5%グループ
(0.005, DATE_TRUNC('week', CURRENT_DATE), 0.026, 0.0052, 0.0052, 0.0052, 0.0052, 0.0052, NOW(), NOW()),
-- 1.0%グループ  
(0.01, DATE_TRUNC('week', CURRENT_DATE), 0.026, 0.0052, 0.0052, 0.0052, 0.0052, 0.0052, NOW(), NOW()),
-- 1.25%グループ
(0.0125, DATE_TRUNC('week', CURRENT_DATE), 0.026, 0.0052, 0.0052, 0.0052, 0.0052, 0.0052, NOW(), NOW()),
-- 1.5%グループ
(0.015, DATE_TRUNC('week', CURRENT_DATE), 0.026, 0.0052, 0.0052, 0.0052, 0.0052, 0.0052, NOW(), NOW()),
-- 2.0%グループ
(0.02, DATE_TRUNC('week', CURRENT_DATE), 0.026, 0.0052, 0.0052, 0.0052, 0.0052, 0.0052, NOW(), NOW());

-- 5. 作成結果確認
SELECT 
    '✅ 週利設定作成完了' as section,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%グループ' as group_name,
    weekly_rate,
    monday_rate,
    tuesday_rate,
    wednesday_rate,
    thursday_rate,
    friday_rate
FROM group_weekly_rates 
WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)
ORDER BY daily_rate_limit;

-- 6. NFTとの対応確認
SELECT 
    '📊 NFTとの対応確認' as section,
    n.daily_rate_limit,
    (n.daily_rate_limit * 100) || '%グループ' as group_name,
    COUNT(*) as nft_count,
    CASE WHEN gwr.daily_rate_limit IS NOT NULL THEN '✅ 週利設定あり' ELSE '❌ 週利設定なし' END as weekly_rate_status
FROM nfts n
LEFT JOIN group_weekly_rates gwr ON n.daily_rate_limit = gwr.daily_rate_limit 
    AND gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)
GROUP BY n.daily_rate_limit, gwr.daily_rate_limit
ORDER BY n.daily_rate_limit;
