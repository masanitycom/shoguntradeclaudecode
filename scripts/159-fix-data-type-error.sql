-- データ型エラーを修正したインポート関数

-- 1. 修正されたインポート関数（データ型を明示的に指定）
CREATE OR REPLACE FUNCTION import_complete_csv_weekly_rates_fixed()
RETURNS TABLE(
    nft_name TEXT,
    weeks_imported INTEGER,
    total_rate NUMERIC
) AS $$
DECLARE
    nft_record RECORD;
    week_num INTEGER;
    week_start DATE;
    week_end DATE;
    weekly_rate_value NUMERIC;
    weeks_count INTEGER;
    total_rate_sum NUMERIC;
    daily_rate NUMERIC;
BEGIN
    -- 基準日: 2025年1月6日（第1週の月曜日）
    
    -- SHOGUN NFT 100-600 (0.5%グループ): 同じデータ
    FOR nft_record IN 
        SELECT id, name::TEXT as name FROM nfts 
        WHERE name IN ('SHOGUN NFT 100', 'SHOGUN NFT 200', 'SHOGUN NFT 300', 'SHOGUN NFT 500', 'SHOGUN NFT 600')
    LOOP
        weeks_count := 0;
        total_rate_sum := 0;
        
        -- 週2-19のデータ
        FOR week_num, weekly_rate_value IN VALUES 
            (2, 1.8), (3, 2.2), (4, 1.1), (5, 0.38), (6, 1.28), (7, 1.1), (8, 1.6), (9, 1.08),
            (10, 0.64), (11, 0.87), (12, 1.01), (13, 0.85), (14, 0.99), (15, 1.39), (16, 1.26), 
            (17, 1.4), (18, 1.23), (19, 0.97)
        LOOP
            week_start := '2025-01-06'::DATE + (week_num - 1) * 7;
            week_end := week_start + 4;
            daily_rate := weekly_rate_value / 5.0;
            
            INSERT INTO nft_weekly_rates (
                nft_id, week_number, week_start_date, week_end_date, weekly_rate,
                monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate
            ) VALUES (
                nft_record.id, week_num, week_start, week_end, weekly_rate_value,
                ROUND(daily_rate::NUMERIC, 3),
                ROUND(daily_rate::NUMERIC, 3),
                ROUND(daily_rate::NUMERIC, 3),
                ROUND(daily_rate::NUMERIC, 3),
                ROUND(daily_rate::NUMERIC, 3)
            ) ON CONFLICT (nft_id, week_number) DO UPDATE SET
                weekly_rate = EXCLUDED.weekly_rate,
                monday_rate = EXCLUDED.monday_rate,
                tuesday_rate = EXCLUDED.tuesday_rate,
                wednesday_rate = EXCLUDED.wednesday_rate,
                thursday_rate = EXCLUDED.thursday_rate,
                friday_rate = EXCLUDED.friday_rate;
                
            weeks_count := weeks_count + 1;
            total_rate_sum := total_rate_sum + weekly_rate_value;
        END LOOP;
        
        RETURN QUERY SELECT nft_record.name, weeks_count, total_rate_sum;
    END LOOP;
    
    -- SHOGUN NFT 1000 (Special): 特別データ
    SELECT id, name::TEXT as name INTO nft_record FROM nfts WHERE name = 'SHOGUN NFT 1000 (Special)' LIMIT 1;
    IF nft_record.id IS NOT NULL THEN
        weeks_count := 0;
        total_rate_sum := 0;
        
        FOR week_num, weekly_rate_value IN VALUES 
            (2, 3.12), (3, 3.81), (4, 4), (5, 2.5), (6, 0.38), (7, 1.58), (8, 2.11), (9, 2.85),
            (10, 1.88), (11, 1.39), (12, 1.37), (13, 1.51), (14, 0.85), (15, 1.49), (16, 1.89), 
            (17, 1.76), (18, 2.02), (19, 2.23), (20, 1.17)
        LOOP
            week_start := '2025-01-06'::DATE + (week_num - 1) * 7;
            week_end := week_start + 4;
            daily_rate := weekly_rate_value / 5.0;
            
            INSERT INTO nft_weekly_rates (
                nft_id, week_number, week_start_date, week_end_date, weekly_rate,
                monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate
            ) VALUES (
                nft_record.id, week_num, week_start, week_end, weekly_rate_value,
                ROUND(daily_rate::NUMERIC, 3),
                ROUND(daily_rate::NUMERIC, 3),
                ROUND(daily_rate::NUMERIC, 3),
                ROUND(daily_rate::NUMERIC, 3),
                ROUND(daily_rate::NUMERIC, 3)
            ) ON CONFLICT (nft_id, week_number) DO UPDATE SET
                weekly_rate = EXCLUDED.weekly_rate,
                monday_rate = EXCLUDED.monday_rate,
                tuesday_rate = EXCLUDED.tuesday_rate,
                wednesday_rate = EXCLUDED.wednesday_rate,
                thursday_rate = EXCLUDED.thursday_rate,
                friday_rate = EXCLUDED.friday_rate;
                
            weeks_count := weeks_count + 1;
            total_rate_sum := total_rate_sum + weekly_rate_value;
        END LOOP;
        
        RETURN QUERY SELECT nft_record.name, weeks_count, total_rate_sum;
    END IF;
    
    -- SHOGUN NFT 1000-10000 (中価格帯): 同じデータパターン
    FOR nft_record IN 
        SELECT id, name::TEXT as name FROM nfts 
        WHERE name IN ('SHOGUN NFT 1000', 'SHOGUN NFT 1100', 'SHOGUN NFT 1177', 'SHOGUN NFT 1200', 
                       'SHOGUN NFT 1217', 'SHOGUN NFT 1227', 'SHOGUN NFT 1300', 'SHOGUN NFT 1350',
                       'SHOGUN NFT 1500', 'SHOGUN NFT 1600', 'SHOGUN NFT 1836', 'SHOGUN NFT 2000',
                       'SHOGUN NFT 2100', 'SHOGUN NFT 3000', 'SHOGUN NFT 3175', 'SHOGUN NFT 4000', 
                       'SHOGUN NFT 5000', 'SHOGUN NFT 6600', 'SHOGUN NFT 8000', 'SHOGUN NFT 10000')
    LOOP
        weeks_count := 0;
        total_rate_sum := 0;
        
        FOR week_num, weekly_rate_value IN VALUES 
            (2, 2.87), (3, 3.56), (4, 4), (5, 2.5), (6, 0.38), (7, 1.58), (8, 2), (9, 2.65),
            (10, 1.88), (11, 1.14), (12, 1.37), (13, 1.51), (14, 0.85), (15, 1.49), (16, 1.89), 
            (17, 1.76), (18, 2.02), (19, 2.23), (20, 1.17)
        LOOP
            week_start := '2025-01-06'::DATE + (week_num - 1) * 7;
            week_end := week_start + 4;
            daily_rate := weekly_rate_value / 5.0;
            
            INSERT INTO nft_weekly_rates (
                nft_id, week_number, week_start_date, week_end_date, weekly_rate,
                monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate
            ) VALUES (
                nft_record.id, week_num, week_start, week_end, weekly_rate_value,
                ROUND(daily_rate::NUMERIC, 3),
                ROUND(daily_rate::NUMERIC, 3),
                ROUND(daily_rate::NUMERIC, 3),
                ROUND(daily_rate::NUMERIC, 3),
                ROUND(daily_rate::NUMERIC, 3)
            ) ON CONFLICT (nft_id, week_number) DO UPDATE SET
                weekly_rate = EXCLUDED.weekly_rate,
                monday_rate = EXCLUDED.monday_rate,
                tuesday_rate = EXCLUDED.tuesday_rate,
                wednesday_rate = EXCLUDED.wednesday_rate,
                thursday_rate = EXCLUDED.thursday_rate,
                friday_rate = EXCLUDED.friday_rate;
                
            weeks_count := weeks_count + 1;
            total_rate_sum := total_rate_sum + weekly_rate_value;
        END LOOP;
        
        RETURN QUERY SELECT nft_record.name, weeks_count, total_rate_sum;
    END LOOP;
    
    -- SHOGUN NFT 30000: 特別データ
    SELECT id, name::TEXT as name INTO nft_record FROM nfts WHERE name = 'SHOGUN NFT 30000' LIMIT 1;
    IF nft_record.id IS NOT NULL THEN
        weeks_count := 0;
        total_rate_sum := 0;
        
        FOR week_num, weekly_rate_value IN VALUES 
            (2, 3.12), (3, 3.81), (4, 4), (5, 2.5), (6, 0.38), (7, 1.58), (8, 2.11), (9, 2.85),
            (10, 1.88), (11, 1.39), (12, 1.37), (13, 1.51), (14, 0.85), (15, 1.49), (16, 1.89), 
            (17, 1.76), (18, 2.02), (19, 2.23), (20, 1.17)
        LOOP
            week_start := '2025-01-06'::DATE + (week_num - 1) * 7;
            week_end := week_start + 4;
            daily_rate := weekly_rate_value / 5.0;
            
            INSERT INTO nft_weekly_rates (
                nft_id, week_number, week_start_date, week_end_date, weekly_rate,
                monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate
            ) VALUES (
                nft_record.id, week_num, week_start, week_end, weekly_rate_value,
                ROUND(daily_rate::NUMERIC, 3),
                ROUND(daily_rate::NUMERIC, 3),
                ROUND(daily_rate::NUMERIC, 3),
                ROUND(daily_rate::NUMERIC, 3),
                ROUND(daily_rate::NUMERIC, 3)
            ) ON CONFLICT (nft_id, week_number) DO UPDATE SET
                weekly_rate = EXCLUDED.weekly_rate,
                monday_rate = EXCLUDED.monday_rate,
                tuesday_rate = EXCLUDED.tuesday_rate,
                wednesday_rate = EXCLUDED.wednesday_rate,
                thursday_rate = EXCLUDED.thursday_rate,
                friday_rate = EXCLUDED.friday_rate;
                
            weeks_count := weeks_count + 1;
            total_rate_sum := total_rate_sum + weekly_rate_value;
        END LOOP;
        
        RETURN QUERY SELECT nft_record.name, weeks_count, total_rate_sum;
    END IF;
    
    -- SHOGUN NFT 100000: 週10から開始（週2-9は0%）
    SELECT id, name::TEXT as name INTO nft_record FROM nfts WHERE name = 'SHOGUN NFT 100000' LIMIT 1;
    IF nft_record.id IS NOT NULL THEN
        weeks_count := 0;
        total_rate_sum := 0;
        
        -- 週2-9は0%
        FOR week_num IN 2..9 LOOP
            week_start := '2025-01-06'::DATE + (week_num - 1) * 7;
            week_end := week_start + 4;
            
            INSERT INTO nft_weekly_rates (
                nft_id, week_number, week_start_date, week_end_date, weekly_rate,
                monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate
            ) VALUES (
                nft_record.id, week_num, week_start, week_end, 0,
                0, 0, 0, 0, 0
            ) ON CONFLICT (nft_id, week_number) DO NOTHING;
            
            weeks_count := weeks_count + 1;
        END LOOP;
        
        -- 週10-20は実際のデータ
        FOR week_num, weekly_rate_value IN VALUES 
            (10, 1.46), (11, 1.37), (12, 1.51), (13, 0.85), (14, 1.49),
            (15, 1.89), (16, 1.76), (17, 2.02), (18, 2.23), (19, 1.17)
        LOOP
            week_start := '2025-01-06'::DATE + (week_num - 1) * 7;
            week_end := week_start + 4;
            daily_rate := weekly_rate_value / 5.0;
            
            INSERT INTO nft_weekly_rates (
                nft_id, week_number, week_start_date, week_end_date, weekly_rate,
                monday_rate, tuesday_rate, wednesday_rate, thursday_rate, friday_rate
            ) VALUES (
                nft_record.id, week_num, week_start, week_end, weekly_rate_value,
                ROUND(daily_rate::NUMERIC, 3),
                ROUND(daily_rate::NUMERIC, 3),
                ROUND(daily_rate::NUMERIC, 3),
                ROUND(daily_rate::NUMERIC, 3),
                ROUND(daily_rate::NUMERIC, 3)
            ) ON CONFLICT (nft_id, week_number) DO UPDATE SET
                weekly_rate = EXCLUDED.weekly_rate,
                monday_rate = EXCLUDED.monday_rate,
                tuesday_rate = EXCLUDED.tuesday_rate,
                wednesday_rate = EXCLUDED.wednesday_rate,
                thursday_rate = EXCLUDED.thursday_rate,
                friday_rate = EXCLUDED.friday_rate;
                
            weeks_count := weeks_count + 1;
            total_rate_sum := total_rate_sum + weekly_rate_value;
        END LOOP;
        
        RETURN QUERY SELECT nft_record.name, weeks_count, total_rate_sum;
    END IF;
    
END;
$$ LANGUAGE plpgsql;

-- 2. 修正されたインポートを実行
SELECT * FROM import_complete_csv_weekly_rates_fixed();

-- 3. 結果確認
SELECT 
    'Data import completed successfully' as status,
    COUNT(*) as total_records
FROM nft_weekly_rates;
