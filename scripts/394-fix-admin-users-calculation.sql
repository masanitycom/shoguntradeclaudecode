-- 管理画面の計算を修正

-- 1. user_nftsテーブルのtotal_earnedを実際の報酬合計で更新
UPDATE user_nfts 
SET total_earned = COALESCE((
    SELECT SUM(dr.reward_amount)
    FROM daily_rewards dr 
    WHERE dr.user_nft_id = user_nfts.id
), 0),
updated_at = NOW()
WHERE is_active = true;

-- 2. 更新後の確認
SELECT 
    '✅ 修正後の管理画面表示データ' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as NFT名,
    un.current_investment as 投資額,
    un.total_earned as 累積報酬,
    CASE 
        WHEN un.current_investment > 0 THEN 
            ROUND((un.total_earned / un.current_investment * 100)::numeric, 8)
        ELSE 0 
    END as 収益率パーセント,
    COUNT(dr.id) as 報酬回数
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
LEFT JOIN daily_rewards dr ON un.id = dr.user_nft_id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'mst1', 'DD123588', 'Norinori0504', 'Sakura0326', 'Sakura0325', 'chococo12', 'H.yui', 'naho1020')
AND un.is_active = true
GROUP BY u.user_id, u.name, n.name, un.current_investment, un.total_earned
ORDER BY u.user_id;

-- 3. 週利が設定されている期間で報酬計算を実行（正しい関数名で）
SELECT calculate_daily_rewards_by_date('2025-02-17'::date, '2025-02-21'::date) as 結果_2月17日週;
SELECT calculate_daily_rewards_by_date('2025-02-24'::date, '2025-02-28'::date) as 結果_2月24日週;
SELECT calculate_daily_rewards_by_date('2025-03-03'::date, '2025-03-07'::date) as 結果_3月3日週;
SELECT calculate_daily_rewards_by_date('2025-03-10'::date, '2025-03-14'::date) as 結果_3月10日週;

-- 4. 最終確認
SELECT 
    '🎉 最終確認結果' as info,
    u.user_id,
    u.name as ユーザー名,
    n.name as NFT名,
    un.current_investment as 投資額,
    un.total_earned as 累積報酬,
    CASE 
        WHEN un.current_investment > 0 THEN 
            ROUND((un.total_earned / un.current_investment * 100)::numeric, 8)
        ELSE 0 
    END as 収益率パーセント
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1', 'SAWA001', 'mst1', 'DD123588', 'Norinori0504', 'Sakura0326', 'Sakura0325', 'chococo12', 'H.yui', 'naho1020')
AND un.is_active = true
ORDER BY u.user_id;

-- 5. 全ユーザーの累積報酬を修正
UPDATE user_nfts 
SET total_earned = COALESCE((
    SELECT SUM(dr.reward_amount)
    FROM daily_rewards dr 
    WHERE dr.user_nft_id = user_nfts.id
), 0),
updated_at = NOW()
WHERE is_active = true;

SELECT '✅ 全ユーザーの累積報酬を修正しました' as status;
