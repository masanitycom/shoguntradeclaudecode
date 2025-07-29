-- 🚨 計算システムテスト

-- 1. 強制日利計算実行
SELECT 
    (force_daily_calculation()->>'success')::BOOLEAN as "計算成功",
    force_daily_calculation()->>'message' as "計算結果メッセージ",
    (force_daily_calculation()->>'processed_count')::INTEGER as "処理件数";

-- 2. 計算結果確認
SELECT 
    COUNT(*) as "本日の報酬レコード数",
    SUM(reward_amount) as "本日の総報酬額",
    AVG(reward_amount) as "平均報酬額"
FROM daily_rewards 
WHERE reward_date = CURRENT_DATE;

-- 3. ユーザー別報酬確認（上位5名）
SELECT 
    u.username as "ユーザー名",
    COUNT(dr.id) as "NFT数",
    SUM(dr.reward_amount) as "本日報酬合計"
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN users u ON un.user_id = u.id
WHERE dr.reward_date = CURRENT_DATE
GROUP BY u.id, u.username
ORDER BY SUM(dr.reward_amount) DESC
LIMIT 5;

-- 4. NFT別報酬確認
SELECT 
    n.name as "NFT名",
    COUNT(dr.id) as "保有者数",
    AVG(dr.reward_amount) as "平均報酬額",
    SUM(dr.reward_amount) as "総報酬額"
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
WHERE dr.reward_date = CURRENT_DATE
GROUP BY n.id, n.name
ORDER BY SUM(dr.reward_amount) DESC;

-- 5. システム健全性チェック
SELECT 
    'システム健全性チェック' as "項目",
    CASE 
        WHEN EXISTS(SELECT 1 FROM daily_rate_groups) AND
             EXISTS(SELECT 1 FROM group_weekly_rates WHERE week_start_date = '2025-02-10') AND
             EXISTS(SELECT 1 FROM daily_rewards WHERE reward_date = CURRENT_DATE)
        THEN '🎉 システム修復完了！'
        ELSE '⚠️ まだ問題があります'
    END as "状態";

-- 6. 最終確認メッセージ
SELECT 
    '=== 計算システムテスト完了 ===' as "テスト結果",
    CURRENT_TIMESTAMP as "実行時刻";
