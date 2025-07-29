-- テーブル制約を修正して週利設定を作成

-- 1. group_weekly_ratesテーブルの制約確認
SELECT 
    '=== group_weekly_rates制約確認 ===' as section,
    tc.constraint_name,
    tc.constraint_type,
    ccu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_name = 'group_weekly_rates'
AND tc.table_schema = 'public';

-- 2. 既存の制約を確認してから追加
DO $$
BEGIN
    -- 制約が存在しない場合のみ追加
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'group_weekly_rates' 
        AND constraint_name = 'unique_week_group'
    ) THEN
        ALTER TABLE group_weekly_rates 
        ADD CONSTRAINT unique_week_group 
        UNIQUE (week_start_date, group_name);
        RAISE NOTICE '制約 unique_week_group を追加しました';
    ELSE
        RAISE NOTICE '制約 unique_week_group は既に存在します';
    END IF;
END $$;

-- 3. 最優先週（2025-02-10）の週利設定を作成
DO $$
DECLARE
    target_week_start date := '2025-02-10';
    group_names text[] := ARRAY['0.5%グループ', '1.0%グループ', '1.25%グループ', '1.5%グループ', '1.75%グループ', '2.0%グループ'];
    weekly_rates numeric[] := ARRAY[0.015, 0.020, 0.023, 0.026, 0.029, 0.032]; -- 1.5%, 2.0%, 2.3%, 2.6%, 2.9%, 3.2%
    i integer;
BEGIN
    RAISE NOTICE '最優先週の週利設定作成開始: % (276 NFT対象)', target_week_start;
    
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
        ) ON CONFLICT (week_start_date, group_name) DO UPDATE SET
            weekly_rate = EXCLUDED.weekly_rate,
            monday_rate = EXCLUDED.monday_rate,
            tuesday_rate = EXCLUDED.tuesday_rate,
            wednesday_rate = EXCLUDED.wednesday_rate,
            thursday_rate = EXCLUDED.thursday_rate,
            friday_rate = EXCLUDED.friday_rate,
            updated_at = NOW();
        
        RAISE NOTICE '作成/更新: % - 週利%', group_names[i], (weekly_rates[i] * 100);
    END LOOP;
    
    RAISE NOTICE '2025-02-10週の週利設定完了';
END $$;

-- 4. 2番目の優先週（2025-02-17）の週利設定も作成
DO $$
DECLARE
    target_week_start date := '2025-02-17';
    group_names text[] := ARRAY['0.5%グループ', '1.0%グループ', '1.25%グループ', '1.5%グループ', '1.75%グループ', '2.0%グループ'];
    weekly_rates numeric[] := ARRAY[0.018, 0.022, 0.025, 0.028, 0.031, 0.034]; -- 少し異なる率
    i integer;
BEGIN
    RAISE NOTICE '2番目優先週の週利設定作成開始: % (5 NFT対象)', target_week_start;
    
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
        ) ON CONFLICT (week_start_date, group_name) DO UPDATE SET
            weekly_rate = EXCLUDED.weekly_rate,
            monday_rate = EXCLUDED.monday_rate,
            tuesday_rate = EXCLUDED.tuesday_rate,
            wednesday_rate = EXCLUDED.wednesday_rate,
            thursday_rate = EXCLUDED.thursday_rate,
            friday_rate = EXCLUDED.friday_rate,
            updated_at = NOW();
    END LOOP;
    
    RAISE NOTICE '2025-02-17週の週利設定完了';
END $$;

-- 5. 作成結果の確認
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
    (friday_rate * 100)::numeric(5,2) as friday_percent,
    -- この週に運用開始するNFT数
    (
        SELECT COUNT(*) 
        FROM user_nfts 
        WHERE is_active = true 
        AND (operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date = gwr.week_start_date
    ) as affected_nfts
FROM group_weekly_rates gwr
WHERE week_start_date IN ('2025-02-10', '2025-02-17')
ORDER BY week_start_date, group_name;

-- 6. NFTとグループの対応確認
SELECT 
    '=== NFTとグループの対応確認 ===' as section,
    n.name as nft_name,
    n.daily_rate_limit,
    n.nft_group,
    COUNT(*) as nft_count
FROM user_nfts un
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true
AND (un.operation_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Tokyo')::date = '2025-02-10'
GROUP BY n.name, n.daily_rate_limit, n.nft_group
ORDER BY COUNT(*) DESC;
