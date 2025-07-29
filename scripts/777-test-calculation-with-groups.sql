-- グループ別計算テスト実行

SELECT '=== 現在の週利設定確認 ===' as section;

-- 現在設定されている週利を確認
SELECT 
    drg.group_name,
    gwr.week_start_date,
    gwr.week_end_date,
    gwr.monday_rate,
    gwr.tuesday_rate,
    gwr.wednesday_rate,
    gwr.thursday_rate,
    gwr.friday_rate
FROM daily_rate_groups drg
LEFT JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
WHERE gwr.week_start_date <= CURRENT_DATE 
AND gwr.week_end_date >= CURRENT_DATE
ORDER BY drg.group_name;

SELECT '=== NFTグループ別分布確認 ===' as section;

-- NFTがどのグループに属しているか確認
SELECT 
    drg.group_name,
    COUNT(n.id) as nft_count,
    AVG(n.daily_rate_limit) as avg_rate_limit,
    string_agg(DISTINCT n.name, ', ' ORDER BY n.name) as nft_names
FROM nfts n
JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
GROUP BY drg.id, drg.group_name
ORDER BY AVG(n.daily_rate_limit);

SELECT '=== ユーザーNFT保有状況 ===' as section;

-- ユーザーのNFT保有状況とグループ分布
SELECT 
    u.email,
    COUNT(un.id) as nft_count,
    SUM(un.purchase_price) as total_investment,
    string_agg(DISTINCT drg.group_name, ', ') as groups
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
WHERE u.is_admin = false
GROUP BY u.id, u.email
ORDER BY total_investment DESC;

SELECT '=== 計算テスト実行 ===' as section;

-- 今日の計算テスト実行
SELECT test_daily_calculation(CURRENT_DATE);

SELECT '=== 期待報酬vs実際報酬の比較 ===' as section;

-- 各ユーザーの期待報酬を計算
WITH expected_rewards AS (
    SELECT 
        u.email,
        n.name as nft_name,
        un.purchase_price,
        n.daily_rate_limit,
        drg.group_name,
        CASE EXTRACT(DOW FROM CURRENT_DATE)
            WHEN 1 THEN gwr.monday_rate
            WHEN 2 THEN gwr.tuesday_rate
            WHEN 3 THEN gwr.wednesday_rate
            WHEN 4 THEN gwr.thursday_rate
            WHEN 5 THEN gwr.friday_rate
            ELSE 0
        END as daily_rate,
        LEAST(
            un.purchase_price * (CASE EXTRACT(DOW FROM CURRENT_DATE)
                WHEN 1 THEN gwr.monday_rate
                WHEN 2 THEN gwr.tuesday_rate
                WHEN 3 THEN gwr.wednesday_rate
                WHEN 4 THEN gwr.thursday_rate
                WHEN 5 THEN gwr.friday_rate
                ELSE 0
            END / 100.0),
            un.purchase_price * (n.daily_rate_limit / 100.0)
        ) as expected_reward
    FROM users u
    JOIN user_nfts un ON u.id = un.user_id
    JOIN nfts n ON un.nft_id = n.id
    JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
    JOIN group_weekly_rates gwr ON drg.id = gwr.group_id
    WHERE u.is_admin = false
    AND un.operation_start_date <= CURRENT_DATE
    AND CURRENT_DATE >= gwr.week_start_date
    AND CURRENT_DATE <= gwr.week_end_date
)
SELECT 
    email,
    nft_name,
    purchase_price,
    daily_rate_limit,
    daily_rate,
    ROUND(expected_reward, 2) as expected_reward
FROM expected_rewards
ORDER BY email, nft_name;

SELECT 'Calculation test with groups completed' as status;
