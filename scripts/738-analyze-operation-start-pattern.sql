-- 運用開始パターンの詳細分析

-- 1. 購入日と運用開始日の関係（正しい仕様確認）
SELECT 
    u.name,
    un.purchase_date,
    un.operation_start_date,
    EXTRACT(DOW FROM un.purchase_date) as purchase_day_of_week, -- 0=日曜, 1=月曜
    EXTRACT(DOW FROM un.operation_start_date) as start_day_of_week, -- 1=月曜日
    un.operation_start_date - un.purchase_date as days_difference,
    CASE 
        WHEN EXTRACT(DOW FROM un.operation_start_date) = 1 THEN '✅ 月曜日開始'
        ELSE '❌ 月曜日以外'
    END as monday_check,
    n.name as nft_name
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true
ORDER BY un.purchase_date
LIMIT 15;

-- 2. 仕様例の検証: 1月6日購入 → 1月20日運用開始
WITH spec_example AS (
    SELECT 
        '2025-01-06'::date as purchase_date,
        '2025-01-20'::date as expected_start_date
)
SELECT 
    purchase_date,
    expected_start_date,
    expected_start_date - purchase_date as days_difference,
    EXTRACT(DOW FROM purchase_date) as purchase_dow,
    EXTRACT(DOW FROM expected_start_date) as start_dow,
    '仕様例: 2週間待機期間' as note
FROM spec_example;

-- 3. 実際のデータが仕様に合致しているか
SELECT 
    COUNT(*) as total_nfts,
    COUNT(CASE WHEN EXTRACT(DOW FROM operation_start_date) = 1 THEN 1 END) as monday_starts,
    COUNT(CASE WHEN operation_start_date >= purchase_date + INTERVAL '14 days' THEN 1 END) as two_week_wait,
    ROUND(
        COUNT(CASE WHEN EXTRACT(DOW FROM operation_start_date) = 1 THEN 1 END) * 100.0 / COUNT(*), 
        2
    ) as monday_percentage
FROM user_nfts 
WHERE is_active = true;
