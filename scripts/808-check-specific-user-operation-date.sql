-- 特定のユーザーの運用開始日確認（SHOGUN NFT 1000 Special保有者）

SELECT '=== CHECKING SPECIFIC USER WITH SHOGUN NFT 1000 SPECIAL ===' as section;

-- SHOGUN NFT 1000 (Special)を保有しているユーザーの詳細
SELECT 'Users with SHOGUN NFT 1000 (Special):' as info;
SELECT 
    un.id as user_nft_id,
    u.id as user_id,
    u.name,
    u.email,
    n.name as nft_name,
    un.purchase_date,
    un.operation_start_date,
    TO_CHAR(un.operation_start_date, 'YYYY-MM-DD DY') as start_date_formatted,
    EXTRACT(DOW FROM un.operation_start_date) as day_of_week_num,
    CASE EXTRACT(DOW FROM un.operation_start_date)
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END as day_name
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE n.name = 'SHOGUN NFT 1000 (Special)'
ORDER BY un.purchase_date;

-- もし画面で2025-02-11と表示されているなら、データベースの値を確認
SELECT 'Check if any dates are actually 2025-02-11:' as info;
SELECT COUNT(*) as count_feb_11
FROM user_nfts
WHERE operation_start_date = '2025-02-11';

SELECT 'Analysis complete' as status;