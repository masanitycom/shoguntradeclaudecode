-- 制約修正後に週利設定を安全に作成

-- 1. 最優先週（2025-02-10）の週利設定を作成
DO $$
DECLARE
    target_week_start date := '2025-02-10';
    group_names text[] := ARRAY['0.5%グループ', '1.0%グループ', '1.25%グループ', '1.5%グループ', '1.75%グループ', '2.0%グループ'];
    weekly_rates numeric[] := ARRAY[0.015, 0.020, 0.023, 0.026, 0.029, 0.032]; -- 1.5%, 2.0%, 2.3%, 2.6%, 2.9%, 3.2%
    i integer;
BEGIN
    RAISE NOTICE '=== 最優先週の週利設定作成開始: % (276 NFT対象) ===', target_week_start;
    
    -- 既存データを削除
    DELETE FROM group_weekly_rates WHERE week_start_date = target_week_start;
    RAISE NOTICE '既存データを削除しました';
    
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
        );
        
        RAISE NOTICE '作成: % - 週利%', group_names[i], (weekly_rates[i] * 100);
    END LOOP;
    
    RAISE NOTICE '=== 2025-02-10週の週利設定完了 ===';
END $$;

-- 2. 2番目の優先週（2025-02-17）の週利設定も作成
DO $$
DECLARE
    target_week_start date := '2025-02-17';
    group_names text[] := ARRAY['0.5%グループ', '1.0%グループ', '1.25%グループ', '1.5%グループ', '1.75%グループ', '2.0%グループ'];
    weekly_rates numeric[] := ARRAY[0.018, 0.022, 0.025, 0.028, 0.031, 0.034]; -- 少し異なる率
    i integer;
BEGIN
    RAISE NOTICE '=== 2番目優先週の週利設定作成開始: % (5 NFT対象) ===', target_week_start;
    
    -- 既存データを削除
    DELETE FROM group_weekly_rates WHERE week_start_date = target_week_start;
    
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
            weekly_rates[i] * 0.2,
            weekly_rates[i] * 0.2,
            weekly_rates[i] * 0.2,
            weekly_rates[i] * 0.2,
            weekly_rates[i] * 0.2,
            'manual',
            NOW(),
            NOW()
        );
    END LOOP;
    
    RAISE NOTICE '=== 2025-02-17週の週利設定完了 ===';
END $$;

-- 3. 作成結果の確認
SELECT 
    '=== 作成された週利設定 ===' as section,
    week_start_date,
    week_end_date,
    group_name,
    (weekly_rate * 100)::numeric(5,2) as weekly_rate_percent,
    (monday_rate * 100)::numeric(5,2) as monday_percent,
    (tuesday_rate * 100)::numeric(5,2) as tuesday_percent,
    (wednesday_rate * 100)::numeric(5,2) as wednesday_percent,
    (thursday_rate * 100)::numeric(5,2) as thursday_percent,
    (friday_rate * 100)::numeric(5,2) as friday_percent
FROM group_weekly_rates
WHERE week_start_date IN ('2025-02-10', '2025-02-17')
ORDER BY week_start_date, group_name;

-- 4. 対象NFT数の確認
SELECT 
    '=== 対象NFT数確認 ===' as section,
    (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date as operation_date,
    COUNT(*) as nft_count,
    COUNT(DISTINCT un.user_id) as user_count,
    SUM(un.purchase_price) as total_investment
FROM user_nfts un
WHERE un.is_active = true
AND (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date IN ('2025-02-10', '2025-02-17')
GROUP BY (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date
ORDER BY operation_date;
