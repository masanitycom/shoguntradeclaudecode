-- 正しいテーブル構造に基づく週利設定修正

-- 1. 既存データを全て削除
TRUNCATE TABLE group_weekly_rates;

-- 2. UUID型のgroup_idで週利設定を作成
INSERT INTO group_weekly_rates (
    group_id,
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
(gen_random_uuid(), DATE_TRUNC('week', CURRENT_DATE), 0.026, 0.0052, 0.0052, 0.0052, 0.0052, 0.0052, NOW(), NOW()),
-- 1.0%グループ  
(gen_random_uuid(), DATE_TRUNC('week', CURRENT_DATE), 0.026, 0.0052, 0.0052, 0.0052, 0.0052, 0.0052, NOW(), NOW()),
-- 1.25%グループ
(gen_random_uuid(), DATE_TRUNC('week', CURRENT_DATE), 0.026, 0.0052, 0.0052, 0.0052, 0.0052, 0.0052, NOW(), NOW()),
-- 1.5%グループ
(gen_random_uuid(), DATE_TRUNC('week', CURRENT_DATE), 0.026, 0.0052, 0.0052, 0.0052, 0.0052, 0.0052, NOW(), NOW()),
-- 2.0%グループ
(gen_random_uuid(), DATE_TRUNC('week', CURRENT_DATE), 0.026, 0.0052, 0.0052, 0.0052, 0.0052, 0.0052, NOW(), NOW());

-- 3. 作成結果確認
SELECT 
    '✅ 週利設定作成結果' as section,
    group_id,
    weekly_rate,
    monday_rate,
    tuesday_rate,
    wednesday_rate,
    thursday_rate,
    friday_rate,
    week_start_date
FROM group_weekly_rates 
ORDER BY created_at;

-- 4. 成功判定
SELECT 
    '🎉 週利設定成功判定' as section,
    CASE 
        WHEN (SELECT COUNT(*) FROM group_weekly_rates) = 5
        THEN '✅ 成功：5つのグループ全てに週利設定完了'
        ELSE '❌ 失敗：週利設定が不完全'
    END as result,
    (SELECT COUNT(*) FROM group_weekly_rates) as created_settings,
    (SELECT COUNT(DISTINCT group_id) FROM group_weekly_rates) as unique_groups;
