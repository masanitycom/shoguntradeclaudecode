-- 週利システムの詳細デバッグ

-- 1. 現在の日付と曜日を確認
SELECT 
  'Current Date Info' as check_type,
  CURRENT_DATE as today,
  EXTRACT(DOW FROM CURRENT_DATE) as day_of_week,
  CASE EXTRACT(DOW FROM CURRENT_DATE)
    WHEN 0 THEN '日曜日'
    WHEN 1 THEN '月曜日'
    WHEN 2 THEN '火曜日'
    WHEN 3 THEN '水曜日'
    WHEN 4 THEN '木曜日'
    WHEN 5 THEN '金曜日'
    WHEN 6 THEN '土曜日'
  END as day_name,
  (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day')::DATE as week_start,
  (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '7 days')::DATE as week_end;

-- 2. daily_rewardsテーブルの構造を確認
SELECT 
  'Daily Rewards Table Structure' as check_type,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. 既存の週利設定を確認
SELECT 
  'Existing Weekly Rates' as check_type,
  gwr.week_start_date,
  gwr.week_end_date,
  drg.group_name,
  gwr.weekly_rate,
  gwr.monday_rate,
  gwr.tuesday_rate,
  gwr.wednesday_rate,
  gwr.thursday_rate,
  gwr.friday_rate
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
ORDER BY gwr.week_start_date DESC, drg.daily_rate_limit;

-- 4. NFTとグループのマッピングを詳細確認
SELECT 
  'NFT Group Mapping Detail' as check_type,
  n.id as nft_id,
  n.name as nft_name,
  n.daily_rate_limit,
  drg.id as group_id,
  drg.group_name,
  COUNT(un.id) as user_count,
  SUM(un.current_investment) as total_investment
FROM nfts n
LEFT JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
LEFT JOIN user_nfts un ON n.id = un.nft_id AND un.is_active = true
WHERE n.is_active = true
GROUP BY n.id, n.name, n.daily_rate_limit, drg.id, drg.group_name
ORDER BY n.daily_rate_limit, n.name;

-- 5. アクティブなuser_nftsの状況確認
SELECT 
  'Active User NFTs Summary' as check_type,
  COUNT(*) as total_active_nfts,
  COUNT(DISTINCT user_id) as unique_users,
  SUM(current_investment) as total_investment,
  AVG(current_investment) as avg_investment,
  MIN(current_investment) as min_investment,
  MAX(current_investment) as max_investment
FROM user_nfts 
WHERE is_active = true AND current_investment > 0;
