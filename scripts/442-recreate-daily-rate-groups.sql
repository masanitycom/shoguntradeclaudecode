-- 日利上限グループを完全に再作成

DO $$
DECLARE
    debug_msg TEXT;
    group_count INTEGER;
BEGIN
    debug_msg := '🔄 日利上限グループ完全再作成開始';
    RAISE NOTICE '%', debug_msg;
    
    -- 既存のグループを全削除
    DELETE FROM daily_rate_groups;
    debug_msg := '🗑️ 既存グループ削除完了';
    RAISE NOTICE '%', debug_msg;
    
    -- 0.5%グループ
    INSERT INTO daily_rate_groups (id, group_name, daily_rate_limit, description)
    VALUES (
        gen_random_uuid(),
        '0.5%グループ',
        0.005,
        '日利上限0.5% - $100,$200,$600特別NFT + $300,$500通常NFT'
    );
    
    -- 1.0%グループ
    INSERT INTO daily_rate_groups (id, group_name, daily_rate_limit, description)
    VALUES (
        gen_random_uuid(),
        '1.0%グループ',
        0.010,
        '日利上限1.0% - $1000,$3000,$5000通常NFT + $1100-$8000特別NFT'
    );
    
    -- 1.25%グループ
    INSERT INTO daily_rate_groups (id, group_name, daily_rate_limit, description)
    VALUES (
        gen_random_uuid(),
        '1.25%グループ',
        0.0125,
        '日利上限1.25% - $10000通常NFT + $1000特別NFT'
    );
    
    -- 1.5%グループ
    INSERT INTO daily_rate_groups (id, group_name, daily_rate_limit, description)
    VALUES (
        gen_random_uuid(),
        '1.5%グループ',
        0.015,
        '日利上限1.5% - $30000通常NFT'
    );
    
    -- 1.75%グループ
    INSERT INTO daily_rate_groups (id, group_name, daily_rate_limit, description)
    VALUES (
        gen_random_uuid(),
        '1.75%グループ',
        0.0175,
        '日利上限1.75% - $50000通常NFT'
    );
    
    -- 2.0%グループ
    INSERT INTO daily_rate_groups (id, group_name, daily_rate_limit, description)
    VALUES (
        gen_random_uuid(),
        '2.0%グループ',
        0.020,
        '日利上限2.0% - $100000通常NFT'
    );
    
    GET DIAGNOSTICS group_count = ROW_COUNT;
    debug_msg := '✅ 日利上限グループ作成完了: ' || group_count || '件';
    RAISE NOTICE '%', debug_msg;
END $$;

-- グループ作成結果の確認
SELECT 
    '📊 日利上限グループ作成結果' as section,
    group_name,
    daily_rate_limit,
    (daily_rate_limit * 100) || '%' as rate_display,
    description
FROM daily_rate_groups
ORDER BY daily_rate_limit;

-- 各グループのNFT数を確認
SELECT 
    '🎯 グループ別NFT分布（再作成後）' as section,
    drg.group_name,
    drg.daily_rate_limit,
    (drg.daily_rate_limit * 100) || '%' as rate_display,
    COUNT(n.id) as nft_count,
    STRING_AGG(n.name ORDER BY n.price, n.name) as nft_names
FROM daily_rate_groups drg
LEFT JOIN nfts n ON n.daily_rate_limit = drg.daily_rate_limit AND n.is_active = true
GROUP BY drg.id, drg.group_name, drg.daily_rate_limit
ORDER BY drg.daily_rate_limit;
