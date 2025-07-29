-- 緊急復旧の実行

-- 1. 今日の日利計算を実行
SELECT 
    '📊 今日の日利計算実行' as info,
    * 
FROM calculate_daily_rewards_for_date(CURRENT_DATE);

-- 2. user_nftsの累計収益を更新
SELECT 
    '💰 user_nfts累計更新' as info,
    update_user_nft_totals() as updated_count;

-- 3. システム健全性チェック
SELECT * FROM system_health_check();

-- 4. ユーザーダッシュボード用データ確認
SELECT 
    '👤 ユーザーダッシュボードデータ確認' as info,
    u.name,
    COUNT(un.id) as nft_count,
    SUM(un.purchase_price) as total_investment,
    SUM(un.total_earned) as total_earned
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE u.name IS NOT NULL
GROUP BY u.id, u.name
HAVING COUNT(un.id) > 0
ORDER BY total_earned DESC
LIMIT 5;

-- 5. 関数の動作確認
SELECT 
    '🔧 関数動作確認' as info,
    'calculate_daily_rewards_for_date' as function_name,
    CASE WHEN EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'calculate_daily_rewards_for_date') 
         THEN 'EXISTS' ELSE 'MISSING' END as status;

SELECT 
    '🔧 関数動作確認' as info,
    'calculate_user_mlm_rank' as function_name,
    CASE WHEN EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'calculate_user_mlm_rank') 
         THEN 'EXISTS' ELSE 'MISSING' END as status;

SELECT 
    '🔧 関数動作確認' as info,
    'calculate_user_mlm_rank' as function_name,
    CASE WHEN EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'calculate_user_mlm_rank') 
         THEN 'EXISTS' ELSE 'MISSING' END as status;

SELECT 
    '🔧 関数動作確認' as info,
    'system_health_check' as function_name,
    CASE WHEN EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'system_health_check') 
         THEN 'EXISTS' ELSE 'MISSING' END as status;

SELECT 
    '🔧 関数動作確認' as info,
    'update_user_nft_totals' as function_name,
    CASE WHEN EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'update_user_nft_totals') 
         THEN 'EXISTS' ELSE 'MISSING' END as status;
