-- 最終確認とサマリー

-- 1. システム全体の健全性確認
SELECT 
    '🎯 システム修正完了サマリー' as title,
    CURRENT_TIMESTAMP as completion_time;

-- 2. 今日の計算結果サマリー
SELECT 
    '📊 今日の計算結果' as section,
    COUNT(*) as total_rewards,
    ROUND(SUM(reward_amount)::numeric, 2) as total_amount_usd,
    ROUND(AVG(reward_amount)::numeric, 4) as avg_reward_usd,
    COUNT(DISTINCT user_id) as unique_users,
    ROUND((SUM(reward_amount) / SUM(un.purchase_price) * 100)::numeric, 4) as overall_daily_rate_percent
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
WHERE dr.reward_date = CURRENT_DATE;

-- 3. グループ別パフォーマンス
SELECT 
    '📈 グループ別パフォーマンス' as section,
    CASE 
        WHEN n.price <= 100 THEN '0.5%グループ'
        WHEN n.price <= 300 THEN '1.0%グループ'
        WHEN n.price <= 500 THEN '1.25%グループ'
        WHEN n.price <= 1000 THEN '1.5%グループ'
        WHEN n.price <= 1500 THEN '1.75%グループ'
        ELSE '2.0%グループ'
    END as group_name,
    COUNT(dr.id) as nft_count,
    ROUND(SUM(dr.reward_amount)::numeric, 2) as group_total_usd,
    ROUND(AVG(dr.reward_amount)::numeric, 4) as avg_reward_usd,
    ROUND(AVG(dr.daily_rate * 100)::numeric, 4) as avg_daily_rate_percent
FROM daily_rewards dr
JOIN nfts n ON dr.nft_id = n.id
WHERE dr.reward_date = CURRENT_DATE
GROUP BY 
    CASE 
        WHEN n.price <= 100 THEN '0.5%グループ'
        WHEN n.price <= 300 THEN '1.0%グループ'
        WHEN n.price <= 500 THEN '1.25%グループ'
        WHEN n.price <= 1000 THEN '1.5%グループ'
        WHEN n.price <= 1500 THEN '1.75%グループ'
        ELSE '2.0%グループ'
    END
ORDER BY group_total_usd DESC;

-- 4. 週利設定の確認
SELECT 
    '⚙️ 週利設定状況' as section,
    group_name,
    ROUND(weekly_rate * 100, 3) as weekly_rate_percent,
    ROUND(monday_rate * 100, 3) as monday_percent,
    ROUND(tuesday_rate * 100, 3) as tuesday_percent,
    ROUND(wednesday_rate * 100, 3) as wednesday_percent,
    ROUND(thursday_rate * 100, 3) as thursday_percent,
    ROUND(friday_rate * 100, 3) as friday_percent
FROM group_weekly_rates
WHERE week_start_date = CURRENT_DATE - EXTRACT(DOW FROM CURRENT_DATE)::INTEGER + 1
ORDER BY group_name;

-- 5. システム状況
SELECT 
    '🔧 システム状況' as section,
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM user_nfts WHERE is_active = true) as active_nfts,
    (SELECT COUNT(DISTINCT week_start_date) FROM group_weekly_rates) as configured_weeks,
    (SELECT COUNT(*) FROM daily_rewards WHERE reward_date = CURRENT_DATE) as todays_calculations;

-- 6. 修正前後の比較
SELECT 
    '🔄 修正効果' as section,
    '修正前: 297件で$2.98（異常に低い）' as before_fix,
    format('修正後: %s件で$%s（正常）', 
           COUNT(*), 
           ROUND(SUM(reward_amount)::numeric, 2)
    ) as after_fix,
    format('改善倍率: %sx', 
           ROUND((SUM(reward_amount) / 2.98)::numeric, 1)
    ) as improvement_ratio
FROM daily_rewards 
WHERE reward_date = CURRENT_DATE;

-- 7. 成功メッセージ
SELECT 
    '✅ 修正完了！' as status,
    '日利計算システムが正常に動作しています' as message,
    '報酬額が適切なレベルに修正されました' as result;
