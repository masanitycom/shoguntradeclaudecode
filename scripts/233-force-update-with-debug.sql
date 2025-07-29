-- デバッグ情報付きの強制更新

-- 1. 更新前の状態確認
SELECT 'BEFORE UPDATE - Problem NFTs' as debug_info;
SELECT name, price, daily_rate_limit, 
       (daily_rate_limit * 100)::text || '%' as current_rate
FROM nfts 
WHERE name IN ('SHOGUN NFT 100', 'SHOGUN NFT 200', 'SHOGUN NFT 3000', 'SHOGUN NFT 30000')
ORDER BY name;

-- 2. 権限とテーブル構造確認
SELECT 'TABLE STRUCTURE CHECK' as debug_info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'nfts' AND column_name = 'daily_rate_limit';

-- 3. 制約確認
SELECT 'CONSTRAINTS CHECK' as debug_info;
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'nfts';

-- 4. トリガー確認
SELECT 'TRIGGERS CHECK' as debug_info;
SELECT trigger_name, event_manipulation, action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'nfts';

-- 5. 一つずつ強制更新（デバッグ付き）
DO $$
DECLARE
    update_count INTEGER;
BEGIN
    -- SHOGUN NFT 100
    RAISE NOTICE 'Updating SHOGUN NFT 100...';
    UPDATE nfts SET daily_rate_limit = 0.005 WHERE name = 'SHOGUN NFT 100';
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE 'Updated % rows for SHOGUN NFT 100', update_count;
    
    -- SHOGUN NFT 200
    RAISE NOTICE 'Updating SHOGUN NFT 200...';
    UPDATE nfts SET daily_rate_limit = 0.005 WHERE name = 'SHOGUN NFT 200';
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE 'Updated % rows for SHOGUN NFT 200', update_count;
    
    -- SHOGUN NFT 3000
    RAISE NOTICE 'Updating SHOGUN NFT 3000...';
    UPDATE nfts SET daily_rate_limit = 0.0125 WHERE name = 'SHOGUN NFT 3000';
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE 'Updated % rows for SHOGUN NFT 3000', update_count;
    
    -- SHOGUN NFT 3175
    RAISE NOTICE 'Updating SHOGUN NFT 3175...';
    UPDATE nfts SET daily_rate_limit = 0.0125 WHERE name = 'SHOGUN NFT 3175';
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE 'Updated % rows for SHOGUN NFT 3175', update_count;
    
    -- SHOGUN NFT 4000
    RAISE NOTICE 'Updating SHOGUN NFT 4000...';
    UPDATE nfts SET daily_rate_limit = 0.0125 WHERE name = 'SHOGUN NFT 4000';
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE 'Updated % rows for SHOGUN NFT 4000', update_count;
    
    -- SHOGUN NFT 5000
    RAISE NOTICE 'Updating SHOGUN NFT 5000...';
    UPDATE nfts SET daily_rate_limit = 0.0125 WHERE name = 'SHOGUN NFT 5000';
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE 'Updated % rows for SHOGUN NFT 5000', update_count;
    
    -- SHOGUN NFT 6600
    RAISE NOTICE 'Updating SHOGUN NFT 6600...';
    UPDATE nfts SET daily_rate_limit = 0.0125 WHERE name = 'SHOGUN NFT 6600';
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE 'Updated % rows for SHOGUN NFT 6600', update_count;
    
    -- SHOGUN NFT 8000
    RAISE NOTICE 'Updating SHOGUN NFT 8000...';
    UPDATE nfts SET daily_rate_limit = 0.0125 WHERE name = 'SHOGUN NFT 8000';
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE 'Updated % rows for SHOGUN NFT 8000', update_count;
    
    -- SHOGUN NFT 10000
    RAISE NOTICE 'Updating SHOGUN NFT 10000...';
    UPDATE nfts SET daily_rate_limit = 0.0125 WHERE name = 'SHOGUN NFT 10000';
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE 'Updated % rows for SHOGUN NFT 10000', update_count;
    
    -- SHOGUN NFT 30000
    RAISE NOTICE 'Updating SHOGUN NFT 30000...';
    UPDATE nfts SET daily_rate_limit = 0.015 WHERE name = 'SHOGUN NFT 30000';
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RAISE NOTICE 'Updated % rows for SHOGUN NFT 30000', update_count;
    
    RAISE NOTICE 'All updates completed!';
END $$;

-- 6. 更新後の確認
SELECT 'AFTER UPDATE - Results' as debug_info;
SELECT name, price, daily_rate_limit, 
       (daily_rate_limit * 100)::text || '%' as new_rate,
       CASE 
           WHEN name = 'SHOGUN NFT 100' AND daily_rate_limit = 0.005 THEN '✅ SUCCESS'
           WHEN name = 'SHOGUN NFT 200' AND daily_rate_limit = 0.005 THEN '✅ SUCCESS'
           WHEN name IN ('SHOGUN NFT 3000', 'SHOGUN NFT 3175', 'SHOGUN NFT 4000', 'SHOGUN NFT 5000', 'SHOGUN NFT 6600', 'SHOGUN NFT 8000', 'SHOGUN NFT 10000') AND daily_rate_limit = 0.0125 THEN '✅ SUCCESS'
           WHEN name = 'SHOGUN NFT 30000' AND daily_rate_limit = 0.015 THEN '✅ SUCCESS'
           ELSE '❌ FAILED'
       END as update_status
FROM nfts 
WHERE name IN (
    'SHOGUN NFT 100', 'SHOGUN NFT 200', 'SHOGUN NFT 3000', 'SHOGUN NFT 3175',
    'SHOGUN NFT 4000', 'SHOGUN NFT 5000', 'SHOGUN NFT 6600', 'SHOGUN NFT 8000',
    'SHOGUN NFT 10000', 'SHOGUN NFT 30000'
)
ORDER BY name;

-- 7. 最終確認
SELECT 'FINAL VERIFICATION' as debug_info;
SELECT 
    COUNT(*) as total_problem_nfts,
    COUNT(CASE 
        WHEN (name = 'SHOGUN NFT 100' AND daily_rate_limit = 0.005) OR
             (name = 'SHOGUN NFT 200' AND daily_rate_limit = 0.005) OR
             (name IN ('SHOGUN NFT 3000', 'SHOGUN NFT 3175', 'SHOGUN NFT 4000', 'SHOGUN NFT 5000', 'SHOGUN NFT 6600', 'SHOGUN NFT 8000', 'SHOGUN NFT 10000') AND daily_rate_limit = 0.0125) OR
             (name = 'SHOGUN NFT 30000' AND daily_rate_limit = 0.015)
        THEN 1 
    END) as successfully_updated,
    CASE 
        WHEN COUNT(CASE 
            WHEN (name = 'SHOGUN NFT 100' AND daily_rate_limit = 0.005) OR
                 (name = 'SHOGUN NFT 200' AND daily_rate_limit = 0.005) OR
                 (name IN ('SHOGUN NFT 3000', 'SHOGUN NFT 3175', 'SHOGUN NFT 4000', 'SHOGUN NFT 5000', 'SHOGUN NFT 6600', 'SHOGUN NFT 8000', 'SHOGUN NFT 10000') AND daily_rate_limit = 0.0125) OR
                 (name = 'SHOGUN NFT 30000' AND daily_rate_limit = 0.015)
            THEN 1 
        END) = COUNT(*)
        THEN '🎉 ALL FIXED!'
        ELSE '❌ STILL ISSUES'
    END as final_status
FROM nfts 
WHERE name IN (
    'SHOGUN NFT 100', 'SHOGUN NFT 200', 'SHOGUN NFT 3000', 'SHOGUN NFT 3175',
    'SHOGUN NFT 4000', 'SHOGUN NFT 5000', 'SHOGUN NFT 6600', 'SHOGUN NFT 8000',
    'SHOGUN NFT 10000', 'SHOGUN NFT 30000'
);
