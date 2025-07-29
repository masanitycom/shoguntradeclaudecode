-- 修正されたCSVデータをインポートして過去の計算を実行

-- 1. NFT個別の週利データをインポート
SELECT * FROM import_complete_csv_weekly_rates();

-- 2. NFT個別の過去日利計算を実行
SELECT * FROM calculate_nft_specific_historical_rewards(2, 19);

-- 3. 結果確認 - NFT別週利設定
SELECT 
    n.name,
    nwr.week_number,
    nwr.weekly_rate,
    nwr.week_start_date
FROM nft_weekly_rates nwr
JOIN nfts n ON nwr.nft_id = n.id
WHERE nwr.week_number IN (2, 10, 18)
ORDER BY n.name, nwr.week_number;

-- 4. 日利報酬の統計（NFT別）
SELECT 
    n.name,
    DATE_PART('week', dr.reward_date) as week_number,
    COUNT(*) as total_rewards,
    SUM(dr.reward_amount) as total_amount,
    AVG(dr.reward_amount) as avg_reward
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
WHERE dr.reward_date >= '2025-01-13' -- 第2週の開始日
GROUP BY n.name, DATE_PART('week', dr.reward_date)
ORDER BY n.name, week_number;

-- 5. 特別確認: SHOGUN NFT 100000の週2-9が0%かチェック
SELECT 
    n.name,
    nwr.week_number,
    nwr.weekly_rate,
    CASE 
        WHEN nwr.weekly_rate = 0 THEN '✓ 正しく0%'
        ELSE '✗ エラー: 0%でない'
    END as status
FROM nft_weekly_rates nwr
JOIN nfts n ON nwr.nft_id = n.id
WHERE n.name = 'SHOGUN NFT 100000'
AND nwr.week_number BETWEEN 2 AND 9
ORDER BY nwr.week_number;

-- 6. 週利データの完全性チェック
SELECT 
    n.name,
    COUNT(nwr.week_number) as weeks_configured,
    MIN(nwr.week_number) as first_week,
    MAX(nwr.week_number) as last_week,
    SUM(nwr.weekly_rate) as total_weekly_rate
FROM nfts n
LEFT JOIN nft_weekly_rates nwr ON n.id = nwr.nft_id
WHERE n.is_active = true
GROUP BY n.name
ORDER BY n.name;

SELECT 'Corrected historical data import completed' as status;
