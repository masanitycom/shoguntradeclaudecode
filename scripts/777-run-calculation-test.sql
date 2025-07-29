-- 月曜日で計算テスト実行

SELECT '=== 月曜日計算テスト ===' as section;

-- 月曜日（2025-07-07）で計算テスト
SELECT test_daily_calculation('2025-07-07'::DATE) as monday_test_result;

-- 火曜日（今日が土曜日なので火曜日もテスト）
SELECT test_daily_calculation('2025-07-08'::DATE) as tuesday_test_result;

-- 現在の日利報酬データ確認
SELECT '=== 既存の日利報酬データ ===' as section;

SELECT 
    dr.reward_date,
    u.email,
    n.name as nft_name,
    un.purchase_price,
    dr.reward_amount,
    ROUND((dr.reward_amount / un.purchase_price * 100)::numeric, 4) as actual_rate_percent
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE dr.reward_date >= '2025-07-01'
ORDER BY dr.reward_date DESC, u.email;
