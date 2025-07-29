-- NFTグループ分布を修正

-- 1. NFTsテーブルのdaily_rate_limitを正しく設定
UPDATE nfts SET daily_rate_limit = 0.005 WHERE price IN (125, 250, 300, 375, 500, 625);
UPDATE nfts SET daily_rate_limit = 0.010 WHERE price IN (1000, 1200, 1250, 2500, 3000);
UPDATE nfts SET daily_rate_limit = 0.0125 WHERE price IN (5000, 7500, 10000);
UPDATE nfts SET daily_rate_limit = 0.015 WHERE price = 30000;
UPDATE nfts SET daily_rate_limit = 0.0175 WHERE price = 50000;
UPDATE nfts SET daily_rate_limit = 0.020 WHERE price >= 100000;

-- 2. 各グループのNFT数を確認
SELECT 
    '📊 修正後グループ別NFT数' as status,
    CASE 
        WHEN daily_rate_limit = 0.005 THEN '0.5%グループ'
        WHEN daily_rate_limit = 0.010 THEN '1.0%グループ'
        WHEN daily_rate_limit = 0.0125 THEN '1.25%グループ'
        WHEN daily_rate_limit = 0.015 THEN '1.5%グループ'
        WHEN daily_rate_limit = 0.0175 THEN '1.75%グループ'
        WHEN daily_rate_limit = 0.020 THEN '2.0%グループ'
        ELSE 'その他'
    END as group_name,
    ROUND(daily_rate_limit * 100, 2) || '%' as daily_rate_limit,
    COUNT(*) as nft_count,
    STRING_AGG(name || '($' || price || ')', ', ') as nft_list
FROM nfts 
WHERE is_active = true
GROUP BY daily_rate_limit
ORDER BY daily_rate_limit;

-- 3. 新しい週利をランダム配分で再設定
SELECT set_weekly_rates_for_all_groups(DATE_TRUNC('week', CURRENT_DATE)::DATE, 0.026);

-- 4. 最新のランダム配分結果を確認
SELECT 
    '🎲 最新ランダム週利配分結果' as status,
    group_name,
    ROUND(weekly_rate * 100, 2) || '%' as weekly_rate,
    CASE WHEN monday_rate = 0 THEN '0%' ELSE ROUND(monday_rate * 100, 2) || '%' END as monday_rate,
    CASE WHEN tuesday_rate = 0 THEN '0%' ELSE ROUND(tuesday_rate * 100, 2) || '%' END as tuesday_rate,
    CASE WHEN wednesday_rate = 0 THEN '0%' ELSE ROUND(wednesday_rate * 100, 2) || '%' END as wednesday_rate,
    CASE WHEN thursday_rate = 0 THEN '0%' ELSE ROUND(thursday_rate * 100, 2) || '%' END as thursday_rate,
    CASE WHEN friday_rate = 0 THEN '0%' ELSE ROUND(friday_rate * 100, 2) || '%' END as friday_rate
FROM group_weekly_rates
WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)
ORDER BY group_name;

-- 5. 0%の日の統計を再確認
SELECT 
    '📊 0%の日の統計（再確認）' as status,
    group_name,
    (CASE WHEN monday_rate = 0 THEN 1 ELSE 0 END +
     CASE WHEN tuesday_rate = 0 THEN 1 ELSE 0 END +
     CASE WHEN wednesday_rate = 0 THEN 1 ELSE 0 END +
     CASE WHEN thursday_rate = 0 THEN 1 ELSE 0 END +
     CASE WHEN friday_rate = 0 THEN 1 ELSE 0 END) as zero_days_count,
    CASE 
        WHEN monday_rate = 0 THEN '月 '
        ELSE ''
    END ||
    CASE 
        WHEN tuesday_rate = 0 THEN '火 '
        ELSE ''
    END ||
    CASE 
        WHEN wednesday_rate = 0 THEN '水 '
        ELSE ''
    END ||
    CASE 
        WHEN thursday_rate = 0 THEN '木 '
        ELSE ''
    END ||
    CASE 
        WHEN friday_rate = 0 THEN '金'
        ELSE ''
    END as zero_days
FROM group_weekly_rates
WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)
ORDER BY group_name;
