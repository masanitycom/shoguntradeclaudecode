-- 過去の週利設定をランダム配分に更新（updated_atカラムなし版）

-- 1. nft_weekly_ratesテーブルの構造確認
SELECT 'Table Structure Check' as status;
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'nft_weekly_rates' 
ORDER BY ordinal_position;

-- 2. 各NFTの週利設定を個別にランダム配分で更新（修正版）
DO $$
DECLARE
    nft_record RECORD;
    new_dist RECORD;
    update_count INTEGER := 0;
BEGIN
    RAISE NOTICE 'Starting historical data update...';
    
    -- 第10週〜第20週の各NFT週利設定を更新
    FOR nft_record IN 
        SELECT id, nft_id, week_number, weekly_rate
        FROM nft_weekly_rates 
        WHERE week_number BETWEEN 10 AND 20
        ORDER BY week_number, nft_id
    LOOP
        -- ランダム配分を生成
        SELECT * INTO new_dist FROM generate_random_distribution(nft_record.weekly_rate);
        
        -- 更新実行（updated_atカラムを除外）
        UPDATE nft_weekly_rates
        SET 
            monday_rate = new_dist.monday_rate,
            tuesday_rate = new_dist.tuesday_rate,
            wednesday_rate = new_dist.wednesday_rate,
            thursday_rate = new_dist.thursday_rate,
            friday_rate = new_dist.friday_rate
        WHERE id = nft_record.id;
        
        update_count := update_count + 1;
        
        -- 進捗表示（50件ごと）
        IF update_count % 50 = 0 THEN
            RAISE NOTICE 'Updated % records...', update_count;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Total updated: % NFT weekly rate records', update_count;
END $$;

-- 3. グループ週利設定も同様に更新
DO $$
DECLARE
    group_record RECORD;
    new_dist RECORD;
    update_count INTEGER := 0;
BEGIN
    RAISE NOTICE 'Starting group weekly rates update...';
    
    -- 第10週〜第20週の各グループ週利設定を更新
    FOR group_record IN 
        SELECT gwr.id, gwr.group_id, gwr.week_number, gwr.weekly_rate, drg.group_name
        FROM group_weekly_rates gwr
        JOIN daily_rate_groups drg ON gwr.group_id = drg.id
        WHERE gwr.week_number BETWEEN 10 AND 20
        ORDER BY gwr.week_number, drg.group_name
    LOOP
        -- ランダム配分を生成
        SELECT * INTO new_dist FROM generate_random_distribution(group_record.weekly_rate);
        
        -- 更新実行
        UPDATE group_weekly_rates
        SET 
            monday_rate = new_dist.monday_rate,
            tuesday_rate = new_dist.tuesday_rate,
            wednesday_rate = new_dist.wednesday_rate,
            thursday_rate = new_dist.thursday_rate,
            friday_rate = new_dist.friday_rate
        WHERE id = group_record.id;
        
        update_count := update_count + 1;
        
        RAISE NOTICE 'Updated group % for week %', group_record.group_name, group_record.week_number;
    END LOOP;
    
    RAISE NOTICE 'Total updated: % group weekly rate records', update_count;
END $$;

-- 4. 更新後の確認
SELECT 'After Update - Sample Data' as status;
SELECT 
    week_number,
    nft_id,
    weekly_rate,
    monday_rate,
    tuesday_rate,
    wednesday_rate,
    thursday_rate,
    friday_rate,
    CASE 
        WHEN monday_rate = 0 THEN 'M休'
        ELSE CONCAT('M', monday_rate::text)
    END ||
    CASE 
        WHEN tuesday_rate = 0 THEN '/T休'
        ELSE CONCAT('/T', tuesday_rate::text)
    END ||
    CASE 
        WHEN wednesday_rate = 0 THEN '/W休'
        ELSE CONCAT('/W', wednesday_rate::text)
    END ||
    CASE 
        WHEN thursday_rate = 0 THEN '/Th休'
        ELSE CONCAT('/Th', thursday_rate::text)
    END ||
    CASE 
        WHEN friday_rate = 0 THEN '/F休'
        ELSE CONCAT('/F', friday_rate::text)
    END as distribution_pattern
FROM nft_weekly_rates 
WHERE week_number IN (10, 15, 20)
ORDER BY week_number, nft_id
LIMIT 15;

-- 5. 統計確認
SELECT 
    'Final Statistics' as status,
    week_number,
    COUNT(*) as total_settings,
    COUNT(CASE WHEN monday_rate = 0 THEN 1 END) as monday_zeros,
    COUNT(CASE WHEN tuesday_rate = 0 THEN 1 END) as tuesday_zeros,
    COUNT(CASE WHEN wednesday_rate = 0 THEN 1 END) as wednesday_zeros,
    COUNT(CASE WHEN thursday_rate = 0 THEN 1 END) as thursday_zeros,
    COUNT(CASE WHEN friday_rate = 0 THEN 1 END) as friday_zeros,
    ROUND(AVG(
        CASE WHEN monday_rate = 0 THEN 0 ELSE 1 END +
        CASE WHEN tuesday_rate = 0 THEN 0 ELSE 1 END +
        CASE WHEN wednesday_rate = 0 THEN 0 ELSE 1 END +
        CASE WHEN thursday_rate = 0 THEN 0 ELSE 1 END +
        CASE WHEN friday_rate = 0 THEN 0 ELSE 1 END
    ), 1) as avg_active_days,
    ROUND(
        (COUNT(CASE WHEN monday_rate = 0 THEN 1 END) + 
         COUNT(CASE WHEN tuesday_rate = 0 THEN 1 END) + 
         COUNT(CASE WHEN wednesday_rate = 0 THEN 1 END) + 
         COUNT(CASE WHEN thursday_rate = 0 THEN 1 END) + 
         COUNT(CASE WHEN friday_rate = 0 THEN 1 END))::NUMERIC / 
        (COUNT(*) * 5) * 100, 1
    ) as zero_rate_percentage
FROM nft_weekly_rates 
WHERE week_number BETWEEN 10 AND 20
GROUP BY week_number
ORDER BY week_number;

-- 6. グループ週利設定の確認
SELECT 
    'Group Weekly Rates After Update' as status,
    gwr.week_number,
    drg.group_name,
    gwr.weekly_rate,
    gwr.monday_rate,
    gwr.tuesday_rate,
    gwr.wednesday_rate,
    gwr.thursday_rate,
    gwr.friday_rate,
    (CASE WHEN gwr.monday_rate = 0 THEN 0 ELSE 1 END +
     CASE WHEN gwr.tuesday_rate = 0 THEN 0 ELSE 1 END +
     CASE WHEN gwr.wednesday_rate = 0 THEN 0 ELSE 1 END +
     CASE WHEN gwr.thursday_rate = 0 THEN 0 ELSE 1 END +
     CASE WHEN gwr.friday_rate = 0 THEN 0 ELSE 1 END) as active_days
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_number BETWEEN 18 AND 20
ORDER BY gwr.week_number, drg.group_name;

SELECT 'Historical data updated to random distribution!' as final_status;
