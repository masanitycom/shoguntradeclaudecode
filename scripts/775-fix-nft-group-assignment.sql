-- NFTのグループ割り当てを日利上限別に正しく修正

SELECT '=== テーブル構造確認 ===' as section;

-- daily_rate_groupsテーブルの構造とデータ確認
SELECT 
    id,
    group_name,
    created_at
FROM daily_rate_groups 
ORDER BY group_name;

-- nftsテーブルの現在の状況
SELECT 
    id,
    name,
    price,
    daily_rate_limit,
    daily_rate_group_id
FROM nfts 
ORDER BY daily_rate_limit, price;

SELECT '=== 日利上限別NFT分布 ===' as section;

-- 日利上限別のNFT数確認
SELECT 
    daily_rate_limit,
    COUNT(*) as nft_count,
    string_agg(name, ', ' ORDER BY price) as nft_names
FROM nfts 
GROUP BY daily_rate_limit 
ORDER BY daily_rate_limit;

-- 必要なグループが存在するか確認
SELECT '=== 必要なグループの存在確認 ===' as section;

DO $$
DECLARE
    group_05_id UUID;
    group_10_id UUID;
    group_125_id UUID;
    group_15_id UUID;
    group_20_id UUID;
BEGIN
    -- 各日利上限に対応するグループを作成または取得
    
    -- 0.5%グループ
    SELECT id INTO group_05_id FROM daily_rate_groups WHERE group_name = '0.5%グループ';
    IF group_05_id IS NULL THEN
        INSERT INTO daily_rate_groups (id, group_name, created_at) 
        VALUES (gen_random_uuid(), '0.5%グループ', NOW()) 
        RETURNING id INTO group_05_id;
        RAISE NOTICE '0.5%%グループを作成: %', group_05_id;
    END IF;
    
    -- 1.0%グループ
    SELECT id INTO group_10_id FROM daily_rate_groups WHERE group_name = '1.0%グループ';
    IF group_10_id IS NULL THEN
        INSERT INTO daily_rate_groups (id, group_name, created_at) 
        VALUES (gen_random_uuid(), '1.0%グループ', NOW()) 
        RETURNING id INTO group_10_id;
        RAISE NOTICE '1.0%%グループを作成: %', group_10_id;
    END IF;
    
    -- 1.25%グループ
    SELECT id INTO group_125_id FROM daily_rate_groups WHERE group_name = '1.25%グループ';
    IF group_125_id IS NULL THEN
        INSERT INTO daily_rate_groups (id, group_name, created_at) 
        VALUES (gen_random_uuid(), '1.25%グループ', NOW()) 
        RETURNING id INTO group_125_id;
        RAISE NOTICE '1.25%%グループを作成: %', group_125_id;
    END IF;
    
    -- 1.5%グループ
    SELECT id INTO group_15_id FROM daily_rate_groups WHERE group_name = '1.5%グループ';
    IF group_15_id IS NULL THEN
        INSERT INTO daily_rate_groups (id, group_name, created_at) 
        VALUES (gen_random_uuid(), '1.5%グループ', NOW()) 
        RETURNING id INTO group_15_id;
        RAISE NOTICE '1.5%%グループを作成: %', group_15_id;
    END IF;
    
    -- 2.0%グループ
    SELECT id INTO group_20_id FROM daily_rate_groups WHERE group_name = '2.0%グループ';
    IF group_20_id IS NULL THEN
        INSERT INTO daily_rate_groups (id, group_name, created_at) 
        VALUES (gen_random_uuid(), '2.0%グループ', NOW()) 
        RETURNING id INTO group_20_id;
        RAISE NOTICE '2.0%%グループを作成: %', group_20_id;
    END IF;
    
    -- NFTを日利上限別にグループに割り当て
    UPDATE nfts SET daily_rate_group_id = group_05_id WHERE daily_rate_limit = 0.5;
    UPDATE nfts SET daily_rate_group_id = group_10_id WHERE daily_rate_limit = 1.0;
    UPDATE nfts SET daily_rate_group_id = group_125_id WHERE daily_rate_limit = 1.25;
    UPDATE nfts SET daily_rate_group_id = group_15_id WHERE daily_rate_limit = 1.5;
    UPDATE nfts SET daily_rate_group_id = group_20_id WHERE daily_rate_limit = 2.0;
    
    RAISE NOTICE 'NFTグループ割り当て完了';
END $$;

-- 修正結果確認
SELECT '=== 修正後のNFTグループ割り当て（日利上限別） ===' as section;

SELECT 
    drg.group_name,
    n.daily_rate_limit as rate_limit,
    COUNT(n.id) as nft_count,
    MIN(n.price) as min_price,
    MAX(n.price) as max_price,
    string_agg(n.name, ', ' ORDER BY n.price) as nft_names
FROM nfts n
JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
GROUP BY drg.id, drg.group_name, n.daily_rate_limit
ORDER BY n.daily_rate_limit;

-- 未割り当てNFTの確認
SELECT '=== 未割り当てNFT ===' as section;
SELECT 
    name,
    price,
    daily_rate_limit,
    daily_rate_group_id
FROM nfts 
WHERE daily_rate_group_id IS NULL
ORDER BY daily_rate_limit, price;

SELECT 'NFT group assignment by daily rate limit completed' as status;
