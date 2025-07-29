-- ユーザー反映問題の診断

-- 1. 現在のシステム状況を確認
SELECT 
  'System Status Check' as check_type,
  COUNT(DISTINCT un.user_id) as active_users,
  COUNT(un.id) as active_user_nfts,
  (SELECT COUNT(*) FROM group_weekly_rates WHERE CURRENT_DATE BETWEEN week_start_date::DATE AND week_end_date::DATE) as current_week_rates,
  (SELECT COUNT(*) FROM daily_rate_groups) as total_groups,
  EXTRACT(DOW FROM CURRENT_DATE) as current_day_of_week,
  CASE 
    WHEN EXTRACT(DOW FROM CURRENT_DATE) BETWEEN 1 AND 5 THEN 'WEEKDAY'
    ELSE 'WEEKEND'
  END as day_type
FROM user_nfts un
WHERE un.is_active = true AND un.current_investment > 0;

-- 2. 過去1週間の日付と曜日を確認
SELECT 
  'Past Week Days' as check_type,
  (CURRENT_DATE - i)::TIMESTAMP as date,
  EXTRACT(DOW FROM (CURRENT_DATE - i))::TEXT as day_of_week,
  CASE 
    WHEN EXTRACT(DOW FROM (CURRENT_DATE - i)) BETWEEN 1 AND 5 THEN 'WEEKDAY'
    ELSE 'WEEKEND'
  END as day_type
FROM generate_series(0, 7) as i
ORDER BY date DESC;

-- 3. デバッグ情報を表示
SELECT 
  'Debug Info' as debug_type,
  'Active User NFTs' as category,
  COUNT(*) as count
FROM user_nfts 
WHERE is_active = true AND current_investment > 0

UNION ALL

SELECT 
  'Debug Info' as debug_type,
  'Weekly Rates Available' as category,
  COUNT(*) as count
FROM group_weekly_rates 
WHERE CURRENT_DATE BETWEEN week_start_date::DATE AND week_end_date::DATE

UNION ALL

SELECT 
  'Debug Info' as debug_type,
  'Daily Rate Groups' as category,
  COUNT(*) as count
FROM daily_rate_groups

UNION ALL

SELECT 
  'Debug Info' as debug_type,
  'Active NFTs' as category,
  COUNT(*) as count
FROM nfts 
WHERE is_active = true;

-- 4. 現在の手動更新後の状況を確認
SELECT 
  'After Manual Update Status' as check_type,
  COUNT(*) as total_active_nfts,
  COUNT(CASE WHEN total_earned > 0 THEN 1 END) as nfts_with_earnings,
  COALESCE(SUM(total_earned), 0) as total_all_earnings,
  COALESCE(AVG(total_earned), 0) as avg_earnings,
  COALESCE(MAX(total_earned), 0) as max_earnings
FROM user_nfts
WHERE is_active = true AND current_investment > 0;

-- 5. ユーザーNFT詳細を確認
SELECT 
  'User NFT Details' as check_type,
  COALESCE(u.name, u.email) as user_name,
  n.name as nft_name,
  n.price as nft_price,
  un.current_investment,
  un.total_earned,
  un.max_earning,
  CASE 
    WHEN un.max_earning > 0 THEN ROUND((un.total_earned / un.max_earning * 100), 2)
    ELSE 0
  END as progress_percent,
  un.is_active
FROM user_nfts un
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true
  AND un.current_investment > 0
ORDER BY un.current_investment DESC
LIMIT 20;

-- 6. システム健全性チェック
SELECT 
  'System Health Check' as check_type,
  'Active Users' as metric,
  COUNT(DISTINCT u.id) as value
FROM users u
WHERE EXISTS (
  SELECT 1 FROM user_nfts un 
  WHERE un.user_id = u.id AND un.is_active = true
)

UNION ALL

SELECT 
  'System Health Check' as check_type,
  'Total Active NFTs' as metric,
  COUNT(*) as value
FROM user_nfts
WHERE is_active = true

UNION ALL

SELECT 
  'System Health Check' as check_type,
  'Total Daily Rewards Records' as metric,
  COUNT(*) as value
FROM daily_rewards

UNION ALL

SELECT 
  'System Health Check' as check_type,
  'Unclaimed Rewards Records' as metric,
  COUNT(*) as value
FROM daily_rewards
WHERE is_claimed = false;
