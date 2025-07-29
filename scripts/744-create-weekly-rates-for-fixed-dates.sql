-- 修正された運用開始日に対応する週利設定を作成（日本時間対応）

-- 1. 必要な週利設定の確認（日本時間）
WITH monday_weeks AS (
    SELECT 
        (operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date as jst_week_start,
        COUNT(*) as nft_count,
        COUNT(DISTINCT user_id) as user_count,
        SUM(purchase_price) as total_investment
    FROM user_nfts 
    WHERE is_active = true
    AND EXTRACT(DOW FROM operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo') = 1 -- 日本時間で月曜日のみ
    GROUP BY (operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date
),
existing_rates AS (
    SELECT DISTINCT week_start_date
    FROM group_weekly_rates
)
SELECT 
    mw.jst_week_start,
    mw.jst_week_start + INTERVAL '4 days' as jst_week_end,
    mw.nft_count,
    mw.user_count,
    mw.total_investment,
    CASE 
        WHEN er.week_start_date IS NOT NULL THEN '✅ 設定済み'
        ELSE '❌ 未設定'
    END as rate_status,
    CASE 
        WHEN mw.nft_count > 100 THEN '🔥 最優先'
        WHEN mw.nft_count > 10 THEN '⚠️ 高優先'
        ELSE '📝 通常'
    END as priority
FROM monday_weeks mw
LEFT JOIN existing_rates er ON mw.jst_week_start = er.week_start_date
ORDER BY mw.nft_count DESC, mw.jst_week_start;

-- 2. 最優先週の週利設定作成（日本時間ベース）
DO $$
DECLARE
    target_week_start date;
    target_nft_count integer;
    group_names text[] := ARRAY['0.5%グループ', '1.0%グループ', '1.25%グループ', '1.5%グループ', '1.75%グループ', '2.0%グループ'];
    weekly_rates numeric[] := ARRAY[0.015, 0.020, 0.023, 0.026, 0.029, 0.032]; -- 1.5%, 2.0%, 2.3%, 2.6%, 2.9%, 3.2%
    i integer;
BEGIN
    -- 最も多くのNFTがある週を取得（日本時間ベース）
    SELECT 
        (operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date,
        COUNT(*)
    INTO target_week_start, target_nft_count
    FROM user_nfts 
    WHERE is_active = true
    AND EXTRACT(DOW FROM operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo') = 1
    GROUP BY (operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date
    ORDER BY COUNT(*) DESC
    LIMIT 1;
    
    RAISE NOTICE '最優先週（日本時間）: % (NFT数: %)', target_week_start, target_nft_count;
    
    -- 各グループの週利設定を作成
    FOR i IN 1..array_length(group_names, 1) LOOP
        INSERT INTO group_weekly_rates (
            week_start_date,
            week_end_date,
            group_name,
            weekly_rate,
            monday_rate,
            tuesday_rate,
            wednesday_rate,
            thursday_rate,
            friday_rate,
            distribution_method,
            created_at,
            updated_at
        ) VALUES (
            target_week_start,
            target_week_start + INTERVAL '4 days',
            group_names[i],
            weekly_rates[i],
            weekly_rates[i] * 0.2, -- 月曜日: 20%
            weekly_rates[i] * 0.2, -- 火曜日: 20%
            weekly_rates[i] * 0.2, -- 水曜日: 20%
            weekly_rates[i] * 0.2, -- 木曜日: 20%
            weekly_rates[i] * 0.2, -- 金曜日: 20%
            'manual',
            NOW(),
            NOW()
        ) ON CONFLICT (week_start_date, group_name) DO NOTHING;
        
        RAISE NOTICE '作成: % - %', group_names[i], weekly_rates[i];
    END LOOP;
    
    RAISE NOTICE '週利設定作成完了（日本時間ベース）: %', target_week_start;
END $$;

-- 3. 作成結果の確認
SELECT 
    '週利設定作成結果（日本時間ベース）' as status,
    week_start_date,
    week_end_date,
    group_name,
    weekly_rate,
    monday_rate + tuesday_rate + wednesday_rate + thursday_rate + friday_rate as total_daily_rate
FROM group_weekly_rates
WHERE week_start_date = (
    SELECT (operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date
    FROM user_nfts 
    WHERE is_active = true
    AND EXTRACT(DOW FROM operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo') = 1
    GROUP BY (operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date
    ORDER BY COUNT(*) DESC
    LIMIT 1
)
ORDER BY group_name;
