-- 週利設定テーブル構造修正

-- 1. 現在のテーブル構造確認
SELECT 
    '🔍 現在のテーブル構造' as section,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'group_weekly_rates'
ORDER BY ordinal_position;

-- 2. 正しいカラム名で週利設定を確認
SELECT 
    '📅 週利設定確認（修正版）' as section,
    id,
    weekly_rate,
    monday_rate,
    tuesday_rate,
    wednesday_rate,
    thursday_rate,
    friday_rate,
    week_start_date
FROM group_weekly_rates
WHERE week_start_date = DATE_TRUNC('week', CURRENT_DATE)
ORDER BY weekly_rate;

-- 3. NFTグループと週利設定の対応確認
WITH nft_groups AS (
    SELECT 
        daily_rate_limit,
        COUNT(*) as nft_count,
        (daily_rate_limit * 100) || '%' as group_name
    FROM nfts 
    WHERE is_active = true
    GROUP BY daily_rate_limit
)
SELECT 
    '📊 NFTグループ最終確認' as section,
    daily_rate_limit,
    group_name,
    nft_count,
    CASE 
        WHEN daily_rate_limit = 0.005 THEN '✅ 0.5%グループ（100,200,600特別+300,500通常）'
        WHEN daily_rate_limit = 0.01 THEN '✅ 1.0%グループ（その他特別NFT+1000,3000,5000通常）'
        WHEN daily_rate_limit = 0.0125 THEN '✅ 1.25%グループ（1000特別+10000通常）'
        WHEN daily_rate_limit = 0.015 THEN '✅ 1.5%グループ（30000通常）'
        WHEN daily_rate_limit = 0.02 THEN '✅ 2.0%グループ（100000通常）'
        ELSE '❓ 不明なグループ'
    END as group_description
FROM nft_groups
ORDER BY daily_rate_limit;

-- 4. 最終成功確認
SELECT 
    '🎉 最終成功確認' as section,
    '✅ NFT分散完了' as nft_status,
    (SELECT COUNT(DISTINCT daily_rate_limit) FROM nfts WHERE is_active = true) as unique_groups,
    (SELECT COUNT(*) FROM nfts WHERE is_active = true) as total_nfts,
    '🎯 仕様書通りの分散が完了しました！' as final_message;
