-- ダッシュボード表示問題の詳細調査

-- 1. 現在の週利設定状況確認
SELECT 
    '📅 週利設定状況' as info,
    gwr.week_start_date as 週開始日,
    gwr.week_end_date as 週終了日,
    drg.group_name as グループ名,
    gwr.weekly_rate as 週利設定,
    gwr.monday_rate as 月曜,
    gwr.tuesday_rate as 火曜,
    gwr.wednesday_rate as 水曜,
    gwr.thursday_rate as 木曜,
    gwr.friday_rate as 金曜,
    CASE 
        WHEN CURRENT_DATE BETWEEN gwr.week_start_date AND gwr.week_end_date 
        THEN '✅ 今週適用中'
        ELSE '❌ 適用外'
    END as 適用状況
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit;

-- 2. 今日の日付と曜日確認
SELECT 
    '📆 今日の情報' as info,
    CURRENT_DATE as 今日の日付,
    EXTRACT(DOW FROM CURRENT_DATE) as 曜日番号,
    CASE EXTRACT(DOW FROM CURRENT_DATE)
        WHEN 1 THEN '月曜日'
        WHEN 2 THEN '火曜日'
        WHEN 3 THEN '水曜日'
        WHEN 4 THEN '木曜日'
        WHEN 5 THEN '金曜日'
        WHEN 6 THEN '土曜日'
        WHEN 0 THEN '日曜日'
    END as 曜日名,
    CASE 
        WHEN EXTRACT(DOW FROM CURRENT_DATE) IN (1,2,3,4,5) THEN '✅ 平日'
        ELSE '❌ 休日'
    END as 営業日判定;

-- 3. 実際の報酬計算ロジック確認
SELECT 
    '🧮 現在の計算ロジック確認' as info,
    dr.user_nft_id,
    dr.reward_date,
    dr.investment_amount as 計算時投資額,
    dr.daily_rate as 適用日利,
    dr.reward_amount as 報酬額,
    dr.investment_amount * dr.daily_rate as 期待計算結果,
    CASE 
        WHEN ABS(dr.reward_amount - (dr.investment_amount * dr.daily_rate)) < 0.01 
        THEN '✅ 計算一致'
        ELSE '❌ 計算不一致'
    END as 計算検証
FROM daily_rewards dr
WHERE dr.reward_date = CURRENT_DATE
LIMIT 10;

-- 4. 固定0.5%計算の証拠確認
SELECT 
    '🔍 固定計算の証拠' as info,
    n.name as NFT名,
    n.price as NFT価格,
    AVG(dr.daily_rate) as 平均適用日利,
    AVG(dr.reward_amount) as 平均報酬額,
    AVG(dr.reward_amount) / AVG(dr.investment_amount) as 実際の日利率,
    CASE 
        WHEN ABS(AVG(dr.reward_amount) / AVG(dr.investment_amount) - 0.005) < 0.0001 
        THEN '❌ 固定0.5%で計算されている'
        ELSE '✅ 動的計算'
    END as 計算方式判定
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
WHERE dr.reward_date >= '2025-07-01'
GROUP BY n.name, n.price
ORDER BY n.price;

-- 5. 週利設定無視の確認
SELECT 
    '⚠️ 週利設定無視の証拠' as info,
    '2025-02-10週に1.8%設定' as 設定内容,
    '実際は全て0.5%固定計算' as 実際の動作,
    '週利配分システムが機能していない' as 問題,
    'calculate_daily_rewards関数を確認が必要' as 対策;
