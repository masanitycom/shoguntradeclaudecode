-- 利益の発生源を特定

-- 1. どの関数が daily_rewards にデータを挿入したか
SELECT 
    '🔍 daily_rewards データ挿入源調査' as section,
    calculation_details,
    COUNT(*) as record_count,
    SUM(reward_amount) as total_amount,
    MIN(created_at) as first_created,
    MAX(created_at) as last_created
FROM daily_rewards
WHERE calculation_details IS NOT NULL
GROUP BY calculation_details
ORDER BY total_amount DESC;

-- 2. user_nfts の total_earned 更新履歴
SELECT 
    '📊 user_nfts 更新状況' as section,
    un.id,
    u.name as user_name,
    n.name as nft_name,
    un.total_earned,
    un.updated_at,
    un.created_at,
    CASE 
        WHEN un.updated_at > un.created_at THEN '更新済み'
        ELSE '未更新'
    END as update_status
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.total_earned > 0
ORDER BY un.total_earned DESC
LIMIT 10;

-- 3. 不正な計算の可能性をチェック
SELECT 
    '⚠️ 不正計算チェック' as section,
    dr.reward_date,
    dr.week_start_date,
    dr.daily_rate,
    dr.reward_amount,
    dr.investment_amount,
    CASE 
        WHEN dr.daily_rate = 0 AND dr.reward_amount > 0 THEN '❌ 日利0なのに報酬あり'
        WHEN dr.investment_amount = 0 AND dr.reward_amount > 0 THEN '❌ 投資額0なのに報酬あり'
        WHEN dr.reward_amount > dr.investment_amount * 0.1 THEN '❌ 異常に高い報酬'
        ELSE '✅ 正常'
    END as anomaly_check
FROM daily_rewards dr
WHERE dr.reward_amount > 0
ORDER BY dr.reward_amount DESC
LIMIT 20;

-- 4. 履歴データの確認（過去に実行された可能性）
SELECT 
    '📅 履歴データ確認' as section,
    DATE_TRUNC('day', created_at) as creation_date,
    COUNT(*) as records_created,
    SUM(reward_amount) as daily_total,
    STRING_AGG(DISTINCT reward_date::TEXT, ', ') as reward_dates
FROM daily_rewards
GROUP BY DATE_TRUNC('day', created_at)
ORDER BY creation_date DESC;
