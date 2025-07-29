-- システムクリーンアップの検証

-- 1. テーブル構造の最終確認
SELECT 
    'users' as table_name,
    column_name, 
    data_type
FROM information_schema.columns 
WHERE table_name = 'users' 
  AND column_name IN ('id', 'name', 'email', 'is_admin')

UNION ALL

SELECT 
    'daily_rewards' as table_name,
    column_name, 
    data_type
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
  AND column_name IN ('id', 'user_id', 'user_nft_id', 'reward_amount', 'reward_date')

UNION ALL

SELECT 
    'user_nfts' as table_name,
    column_name, 
    data_type
FROM information_schema.columns 
WHERE table_name = 'user_nfts' 
  AND column_name IN ('id', 'user_id', 'nft_id', 'purchase_price', 'is_active')

ORDER BY table_name, column_name;

-- 2. 現在のシステム状況
SELECT 
    'システム統計' as category,
    '総ユーザー数' as metric,
    COUNT(*)::TEXT as value
FROM users WHERE is_admin = false

UNION ALL

SELECT 
    'システム統計' as category,
    'アクティブNFT数' as metric,
    COUNT(*)::TEXT as value
FROM user_nfts WHERE is_active = true

UNION ALL

SELECT 
    'システム統計' as category,
    '総報酬レコード数' as metric,
    COUNT(*)::TEXT as value
FROM daily_rewards

UNION ALL

SELECT 
    'システム統計' as category,
    '総報酬金額' as metric,
    COALESCE(SUM(reward_amount), 0)::TEXT as value
FROM daily_rewards

UNION ALL

SELECT 
    'システム統計' as category,
    '週利設定数' as metric,
    COUNT(*)::TEXT as value
FROM group_weekly_rates;

-- 3. 関数の動作テスト
SELECT 
    'force_daily_calculation関数テスト' as test_name,
    status,
    message,
    processed_users,
    total_rewards
FROM force_daily_calculation();

-- 4. ユーザー報酬サマリーテスト（最初のユーザー）
SELECT 
    'ユーザー報酬サマリーテスト' as test_name,
    total_investment,
    total_rewards,
    reward_percentage,
    active_nfts
FROM get_user_reward_summary((SELECT id FROM users WHERE is_admin = false LIMIT 1));

-- 5. システム統計テスト
SELECT 
    'システム統計テスト' as test_name,
    total_users,
    active_nfts,
    total_investment,
    total_rewards,
    pending_applications
FROM get_system_statistics();
