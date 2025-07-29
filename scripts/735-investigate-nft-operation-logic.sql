-- NFT運用開始ロジックの調査

-- 1. 仕様書の確認: NFT運用開始ルール
/*
仕様書より:
- 購入日から1週空けて翌月曜日からの運用開始
- これが正しい仕様であることを確認
*/

-- 2. 実際のNFT購入日と運用開始日の関係を確認
SELECT 
    u.name,
    un.purchase_date,
    un.operation_start_date,
    EXTRACT(DOW FROM un.operation_start_date) as start_day_of_week, -- 1=月曜日
    un.operation_start_date - un.purchase_date as days_difference,
    n.name as nft_name,
    n.price
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true
ORDER BY un.purchase_date
LIMIT 20;

-- 3. 週利設定期間の確認
SELECT 
    week_start_date,
    COUNT(*) as rate_count,
    MIN(week_start_date) as earliest_week,
    MAX(week_start_date) as latest_week
FROM group_weekly_rates 
GROUP BY week_start_date
ORDER BY week_start_date;

-- 4. 運用開始日と週利設定期間の関係
SELECT 
    'NFT運用開始日範囲' as category,
    MIN(operation_start_date) as earliest_date,
    MAX(operation_start_date) as latest_date
FROM user_nfts 
WHERE is_active = true
UNION ALL
SELECT 
    '週利設定期間範囲' as category,
    MIN(week_start_date) as earliest_date,
    MAX(week_start_date) as latest_date
FROM group_weekly_rates;

-- 5. 具体例: 購入日から運用開始日の計算ロジック確認
WITH sample_purchases AS (
    SELECT 
        purchase_date,
        operation_start_date,
        -- 購入日の翌週月曜日を計算
        purchase_date + INTERVAL '7 days' + 
        (1 - EXTRACT(DOW FROM purchase_date + INTERVAL '7 days'))::int * INTERVAL '1 day' as calculated_monday
    FROM user_nfts 
    WHERE is_active = true
    LIMIT 10
)
SELECT 
    purchase_date,
    operation_start_date,
    calculated_monday,
    CASE 
        WHEN operation_start_date = calculated_monday THEN '✅ 正確'
        ELSE '❌ 不一致'
    END as logic_check
FROM sample_purchases;
