-- =====================================================================
-- 日利計算の正確性を検証
-- =====================================================================

-- 1. 今日の計算結果の詳細を確認
SELECT 
    '📊 今日の計算結果詳細' as status,
    dr.reward_date,
    COUNT(*) as total_records,
    SUM(dr.reward_amount) as total_rewards,
    AVG(dr.reward_amount) as avg_reward,
    MIN(dr.reward_amount) as min_reward,
    MAX(dr.reward_amount) as max_reward,
    COUNT(DISTINCT dr.user_nft_id) as unique_nfts,
    COUNT(DISTINCT dr.user_id) as unique_users
FROM daily_rewards dr
WHERE dr.reward_date = CURRENT_DATE
GROUP BY dr.reward_date;

-- 2. グループ別の計算結果を確認
SELECT 
    '🎯 グループ別計算結果' as status,
    drg.group_name,
    drg.daily_rate_limit,
    COUNT(dr.id) as reward_records,
    SUM(dr.reward_amount) as group_total_rewards,
    AVG(dr.reward_amount) as avg_reward_per_nft,
    SUM(dr.investment_amount) as total_investment,
    AVG(dr.daily_rate) as avg_daily_rate_used,
    ROUND((SUM(dr.reward_amount) / SUM(dr.investment_amount) * 100)::numeric, 4) as actual_rate_percent
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
WHERE dr.reward_date = CURRENT_DATE
GROUP BY drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;

-- 3. 今週の週利設定を確認
SELECT 
    '📅 今週の週利設定' as status,
    gwr.week_start_date,
    gwr.week_end_date,
    drg.group_name,
    gwr.weekly_rate,
    gwr.monday_rate,
    gwr.tuesday_rate,
    gwr.wednesday_rate,
    gwr.thursday_rate,
    gwr.friday_rate,
    CASE EXTRACT(DOW FROM CURRENT_DATE)
        WHEN 1 THEN gwr.monday_rate
        WHEN 2 THEN gwr.tuesday_rate
        WHEN 3 THEN gwr.wednesday_rate
        WHEN 4 THEN gwr.thursday_rate
        WHEN 5 THEN gwr.friday_rate
        ELSE 0
    END as todays_expected_rate
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)::date
ORDER BY drg.daily_rate_limit;

-- 4. 期待される報酬額と実際の報酬額を比較
WITH expected_calculations AS (
    SELECT 
        drg.group_name,
        drg.daily_rate_limit,
        COUNT(un.id) as nft_count,
        SUM(un.current_investment) as total_investment,
        CASE EXTRACT(DOW FROM CURRENT_DATE)
            WHEN 1 THEN gwr.monday_rate
            WHEN 2 THEN gwr.tuesday_rate
            WHEN 3 THEN gwr.wednesday_rate
            WHEN 4 THEN gwr.thursday_rate
            WHEN 5 THEN gwr.friday_rate
            ELSE 0
        END as expected_daily_rate,
        SUM(un.current_investment) * 
        CASE EXTRACT(DOW FROM CURRENT_DATE)
            WHEN 1 THEN gwr.monday_rate
            WHEN 2 THEN gwr.tuesday_rate
            WHEN 3 THEN gwr.wednesday_rate
            WHEN 4 THEN gwr.thursday_rate
            WHEN 5 THEN gwr.friday_rate
            ELSE 0
        END as expected_total_reward
    FROM user_nfts un
    JOIN nfts n ON un.nft_id = n.id
    JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
    LEFT JOIN group_weekly_rates gwr ON gwr.group_id = drg.id 
        AND gwr.week_start_date = DATE_TRUNC('week', CURRENT_DATE)::date
    WHERE un.is_active = true 
    AND un.current_investment > 0
    AND n.is_active = true
    GROUP BY drg.group_name, drg.daily_rate_limit, gwr.monday_rate, gwr.tuesday_rate, 
             gwr.wednesday_rate, gwr.thursday_rate, gwr.friday_rate
),
actual_calculations AS (
    SELECT 
        drg.group_name,
        drg.daily_rate_limit,
        COUNT(dr.id) as actual_records,
        SUM(dr.investment_amount) as actual_investment,
        SUM(dr.reward_amount) as actual_total_reward,
        AVG(dr.daily_rate) as actual_avg_rate
    FROM daily_rewards dr
    JOIN user_nfts un ON dr.user_nft_id = un.id
    JOIN nfts n ON un.nft_id = n.id
    JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
    WHERE dr.reward_date = CURRENT_DATE
    GROUP BY drg.group_name, drg.daily_rate_limit
)
SELECT 
    '🔍 期待値vs実際値比較' as status,
    ec.group_name,
    ec.nft_count,
    ec.total_investment as expected_investment,
    ac.actual_investment,
    ROUND(ec.expected_daily_rate * 100, 4) as expected_rate_percent,
    ROUND(ac.actual_avg_rate * 100, 4) as actual_rate_percent,
    ROUND(ec.expected_total_reward, 2) as expected_reward,
    ROUND(ac.actual_total_reward, 2) as actual_reward,
    ROUND(ac.actual_total_reward - ec.expected_total_reward, 2) as difference,
    CASE 
        WHEN ec.expected_total_reward > 0 THEN
            ROUND(((ac.actual_total_reward - ec.expected_total_reward) / ec.expected_total_reward * 100)::numeric, 2)
        ELSE 0
    END as difference_percent
FROM expected_calculations ec
FULL OUTER JOIN actual_calculations ac ON ec.group_name = ac.group_name
ORDER BY ec.daily_rate_limit NULLS LAST;

-- 5. 個別NFTの計算例を確認（上位10件）
SELECT 
    '💰 個別NFT計算例（上位10件）' as status,
    dr.user_id,
    n.name as nft_name,
    drg.group_name,
    dr.investment_amount,
    ROUND(dr.daily_rate * 100, 4) as daily_rate_percent,
    dr.reward_amount,
    ROUND((dr.reward_amount / dr.investment_amount * 100)::numeric, 4) as actual_rate_percent,
    dr.calculation_details
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
WHERE dr.reward_date = CURRENT_DATE
ORDER BY dr.reward_amount DESC
LIMIT 10;

-- 6. 今日の曜日と適用される日利を確認
SELECT 
    '📅 今日の曜日情報' as status,
    CURRENT_DATE as today,
    EXTRACT(DOW FROM CURRENT_DATE) as day_of_week_number,
    CASE EXTRACT(DOW FROM CURRENT_DATE)
        WHEN 0 THEN '日曜日'
        WHEN 1 THEN '月曜日'
        WHEN 2 THEN '火曜日'
        WHEN 3 THEN '水曜日'
        WHEN 4 THEN '木曜日'
        WHEN 5 THEN '金曜日'
        WHEN 6 THEN '土曜日'
    END as day_name,
    CASE 
        WHEN EXTRACT(DOW FROM CURRENT_DATE) BETWEEN 1 AND 5 THEN '平日（計算対象）'
        ELSE '休日（計算対象外）'
    END as calculation_status;

-- 7. 300%キャップに達したNFTがあるかチェック
SELECT 
    '🎯 300%キャップ状況' as status,
    COUNT(*) as total_active_nfts,
    COUNT(CASE WHEN total_earned >= max_earning THEN 1 END) as completed_nfts,
    COUNT(CASE WHEN total_earned >= max_earning * 0.9 THEN 1 END) as near_completion_nfts,
    AVG(CASE WHEN max_earning > 0 THEN (total_earned / max_earning * 100) ELSE 0 END) as avg_completion_percent
FROM user_nfts
WHERE is_active = true AND current_investment > 0;

-- 8. エラーや異常値のチェック
SELECT 
    '⚠️ 異常値チェック' as status,
    COUNT(CASE WHEN reward_amount <= 0 THEN 1 END) as zero_or_negative_rewards,
    COUNT(CASE WHEN daily_rate > 0.05 THEN 1 END) as high_daily_rates,
    COUNT(CASE WHEN reward_amount > investment_amount * 0.05 THEN 1 END) as excessive_rewards,
    COUNT(CASE WHEN daily_rate IS NULL THEN 1 END) as null_daily_rates
FROM daily_rewards
WHERE reward_date = CURRENT_DATE;

-- 9. 総合検証結果
SELECT 
    '✅ 総合検証結果' as status,
    '計算完了' as calculation_status,
    COUNT(*) as total_processed,
    SUM(reward_amount) as total_rewards_paid,
    ROUND(AVG(reward_amount), 2) as average_reward,
    ROUND(SUM(reward_amount) / SUM(investment_amount) * 100, 4) as overall_rate_percent,
    COUNT(DISTINCT user_id) as users_benefited,
    CURRENT_TIMESTAMP as verification_time
FROM daily_rewards
WHERE reward_date = CURRENT_DATE;
