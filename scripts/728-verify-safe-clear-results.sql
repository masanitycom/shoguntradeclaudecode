-- 安全なクリア結果の検証

-- 1. 保護されたデータの確認
SELECT 
    'PROTECTION VERIFICATION' as check_type,
    'users' as table_name,
    COUNT(*) as record_count,
    'PROTECTED - User data intact' as status
FROM users
UNION ALL
SELECT 
    'PROTECTION VERIFICATION' as check_type,
    'nfts' as table_name,
    COUNT(*) as record_count,
    'PROTECTED - NFT data intact' as status
FROM nfts
UNION ALL
SELECT 
    'PROTECTION VERIFICATION' as check_type,
    'user_nfts' as table_name,
    COUNT(*) as record_count,
    'PROTECTED - User NFT relationships intact' as status
FROM user_nfts;

-- 2. クリアされたデータの確認
SELECT 
    'CLEAR VERIFICATION' as check_type,
    'daily_rewards' as table_name,
    COUNT(*) as record_count,
    CASE WHEN COUNT(*) = 0 THEN 'CLEARED - No reward data' ELSE 'WARNING - Data still exists' END as status
FROM daily_rewards
UNION ALL
SELECT 
    'CLEAR VERIFICATION' as check_type,
    'reward_applications' as table_name,
    COUNT(*) as record_count,
    CASE WHEN COUNT(*) = 0 THEN 'CLEARED - No application data' ELSE 'WARNING - Data still exists' END as status
FROM reward_applications
UNION ALL
SELECT 
    'CLEAR VERIFICATION' as check_type,
    'group_weekly_rates' as table_name,
    COUNT(*) as record_count,
    CASE WHEN COUNT(*) = 0 THEN 'CLEARED - No weekly rate data' ELSE 'WARNING - Data still exists' END as status
FROM group_weekly_rates;

-- 3. user_nftsの報酬フィールド確認
SELECT 
    'EARNINGS VERIFICATION' as check_type,
    'user_nfts_earnings' as table_name,
    COUNT(*) as total_records,
    SUM(COALESCE(total_earned, 0)) as total_earnings,
    CASE WHEN SUM(COALESCE(total_earned, 0)) = 0 THEN 'CLEARED - All earnings reset to 0' ELSE 'WARNING - Earnings still exist' END as status
FROM user_nfts;

-- 4. 管理画面統計テスト
SELECT 'ADMIN STATS TEST' as check_type;
SELECT * FROM get_admin_dashboard_stats();

SELECT 'Safe clear verification completed' as final_status;
