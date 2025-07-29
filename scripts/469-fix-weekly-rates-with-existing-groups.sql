-- 既存のdaily_rate_groupsを使用して週利設定を作成

-- 1. 既存のgroup_weekly_ratesを削除
TRUNCATE TABLE group_weekly_rates;

-- 2. daily_rate_groupsの既存IDを使用して週利設定を作成
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
)
SELECT 
    id as group_id,
    DATE_TRUNC('week', CURRENT_DATE) as week_start_date,
    0.026 as weekly_rate,
    0.0052 as monday_rate,
    0.0052 as tuesday_rate,
    0.0052 as wednesday_rate,
    0.0052 as thursday_rate,
    0.0052 as friday_rate,
    NOW() as created_at,
    NOW() as updated_at
FROM daily_rate_groups
ORDER BY daily_rate_limit;

-- 3. 作成結果確認
SELECT 
    '✅ 週利設定作成結果' as section,
    gwr.group_id,
    drg.daily_rate_limit,
    (drg.daily_rate_limit * 100) || '%グループ' as group_name,
    gwr.weekly_rate,
    gwr.monday_rate,
    gwr.tuesday_rate,
    gwr.wednesday_rate,
    gwr.thursday_rate,
    gwr.friday_rate,
    gwr.week_start_date
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
ORDER BY drg.daily_rate_limit;

-- 4. NFTグループとの対応確認
SELECT 
    '📊 NFTグループとの対応' as section,
    n.daily_rate_limit,
    (n.daily_rate_limit * 100) || '%グループ' as group_name,
    COUNT(*) as nft_count,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM group_weekly_rates gwr 
            JOIN daily_rate_groups drg ON gwr.group_id = drg.id
            WHERE drg.daily_rate_limit = n.daily_rate_limit
        ) THEN '✅ 週利設定あり' 
        ELSE '❌ 週利設定なし' 
    END as weekly_rate_status
FROM nfts n
GROUP BY n.daily_rate_limit
ORDER BY n.daily_rate_limit;

-- 5. 成功判定
SELECT 
    '🎉 週利設定成功判定' as section,
    CASE 
        WHEN (SELECT COUNT(*) FROM group_weekly_rates) >= 5
        THEN '✅ 成功：週利設定完了'
        ELSE '❌ 失敗：週利設定が不完全'
    END as result,
    (SELECT COUNT(*) FROM group_weekly_rates) as created_settings,
    (SELECT COUNT(DISTINCT group_id) FROM group_weekly_rates) as unique_groups;
