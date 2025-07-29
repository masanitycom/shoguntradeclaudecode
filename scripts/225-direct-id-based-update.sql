-- IDを使った直接更新で確実に修正

-- 1. 現在の問題を確認
SELECT 'Current Problems' as status, 
       n.id, n.name, n.daily_rate_limit as current_rate, 
       drg.daily_rate_limit as target_rate,
       drg.group_name
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.group_id = drg.id
WHERE ABS(n.daily_rate_limit - drg.daily_rate_limit) >= 0.0001
ORDER BY n.name;

-- 2. IDを使って直接更新（確実に実行されるよう）

-- 0.5%グループのNFTを更新
UPDATE nfts SET daily_rate_limit = 0.005 
WHERE group_id = '26057cfc-7178-41f4-8ee7-1d003cfbfb15';

-- 1.25%グループのNFTを更新  
UPDATE nfts SET daily_rate_limit = 0.0125 
WHERE group_id = '00da250c-ffa9-4054-88d9-d41970093aa3';

-- 1.5%グループのNFTを更新
UPDATE nfts SET daily_rate_limit = 0.015 
WHERE group_id = 'ddac7755-84f7-40a3-9434-6ea6f5329957';

-- 3. 更新結果を確認
SELECT 'After ID Update' as status, 
       n.id, n.name, n.daily_rate_limit as updated_rate, 
       drg.daily_rate_limit as group_rate,
       drg.group_name
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.group_id = drg.id
ORDER BY n.price;

-- 4. 最終検証
SELECT 
    'Final Perfect Check' as check_type,
    n.name,
    n.price,
    (n.daily_rate_limit * 100) as nft_percentage,
    n.is_special,
    drg.group_name,
    (drg.daily_rate_limit * 100) as group_percentage,
    CASE 
        WHEN ABS(n.daily_rate_limit - drg.daily_rate_limit) < 0.0001 THEN '✅ PERFECT MATCH'
        ELSE '❌ STILL MISMATCH'
    END as status
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.group_id = drg.id
ORDER BY n.price;

-- 5. 残っている問題があれば表示
SELECT 
    'Remaining Issues' as check_type,
    COUNT(*) as remaining_mismatches
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.group_id = drg.id
WHERE ABS(n.daily_rate_limit - drg.daily_rate_limit) >= 0.0001;

-- 6. 成功確認
SELECT 
    'Success Summary' as check_type,
    COUNT(*) as total_nfts,
    COUNT(CASE WHEN ABS(n.daily_rate_limit - drg.daily_rate_limit) < 0.0001 THEN 1 END) as perfect_matches,
    ROUND(
        (COUNT(CASE WHEN ABS(n.daily_rate_limit - drg.daily_rate_limit) < 0.0001 THEN 1 END) * 100.0 / COUNT(*)), 
        2
    ) as success_percentage
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.group_id = drg.id;
