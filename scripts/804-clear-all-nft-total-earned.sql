-- 全ユーザーのNFT total_earnedデータをクリア
-- ユーザーからの報告：すべてのNFTで$1.50などの不正な獲得額が表示されている

SELECT '=== CLEARING ALL NFT TOTAL_EARNED DATA ===' as section;

-- 1. 現在のtotal_earnedデータ状況確認
SELECT 'Before clearing - Current total_earned statistics:' as info;
SELECT 
    COUNT(*) as total_user_nfts,
    COUNT(*) FILTER (WHERE total_earned > 0) as nfts_with_earnings,
    SUM(total_earned) as total_earnings_sum,
    AVG(total_earned) as avg_earnings,
    MIN(total_earned) as min_earnings,
    MAX(total_earned) as max_earnings
FROM user_nfts;

-- 2. $1.50の具体的な件数確認
SELECT 'Records with $1.50 earnings:' as info;
SELECT COUNT(*) as count_with_150
FROM user_nfts 
WHERE total_earned = 1.50;

-- 3. 0以外のtotal_earnedを持つすべてのレコード確認
SELECT 'All non-zero total_earned records:' as info;
SELECT 
    un.id,
    un.user_id,
    u.name,
    n.name as nft_name,
    un.total_earned,
    un.purchase_date,
    un.operation_start_date
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.total_earned > 0
ORDER BY un.total_earned DESC, un.purchase_date;

-- 4. 全ユーザーのtotal_earnedを0にリセット
SELECT 'Clearing all total_earned data...' as action;
UPDATE user_nfts 
SET total_earned = 0.00,
    updated_at = NOW()
WHERE total_earned > 0;

-- 5. 更新結果確認
SELECT 'After clearing - Updated statistics:' as info;
SELECT 
    COUNT(*) as total_user_nfts,
    COUNT(*) FILTER (WHERE total_earned > 0) as nfts_with_earnings,
    SUM(total_earned) as total_earnings_sum,
    MAX(total_earned) as max_earnings
FROM user_nfts;

-- 6. 更新されたレコード数を報告
SELECT 'Update completed successfully!' as status;
SELECT 'All NFT total_earned values have been reset to 0.00' as result;

SELECT '=== CLEANUP COMPLETE ===' as section;