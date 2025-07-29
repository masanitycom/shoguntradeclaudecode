-- 修正された日利計算システムのテスト

-- 1. テスト実行前の状況確認
SELECT 
  'Pre-test Status' as status,
  COUNT(*) as active_user_nfts
FROM user_nfts 
WHERE is_active = true AND current_investment > 0;

-- 2. 今週の週利設定確認
SELECT 
  'Weekly Rates Check' as check_type,
  gwr.week_start_date,
  drg.group_name,
  ROUND(gwr.weekly_rate * 100, 2) || '%' as weekly_rate,
  ROUND(gwr.monday_rate * 100, 3) || '%' as monday,
  ROUND(gwr.tuesday_rate * 100, 3) || '%' as tuesday,
  ROUND(gwr.wednesday_rate * 100, 3) || '%' as wednesday,
  ROUND(gwr.thursday_rate * 100, 3) || '%' as thursday,
  ROUND(gwr.friday_rate * 100, 3) || '%' as friday
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE gwr.week_start_date = (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day')::DATE
ORDER BY drg.daily_rate_limit;

-- 3. 日利計算を実行
SELECT 
  'Daily Calculation Test' as test_type,
  *
FROM calculate_daily_rewards_batch(CURRENT_DATE);

-- 4. 計算結果を確認
SELECT 
  'Calculation Results' as result_type,
  dr.reward_date,
  COUNT(*) as total_records,
  COUNT(DISTINCT dr.user_nft_id) as unique_user_nfts,
  COUNT(DISTINCT dr.user_id) as unique_users,
  ROUND(SUM(dr.reward_amount), 2) as total_rewards,
  ROUND(AVG(dr.reward_amount), 4) as avg_reward,
  ROUND(MIN(dr.reward_amount), 4) as min_reward,
  ROUND(MAX(dr.reward_amount), 4) as max_reward
FROM daily_rewards dr
WHERE dr.reward_date = CURRENT_DATE
GROUP BY dr.reward_date;

-- 5. サンプルデータを表示（usersテーブルの正しいカラム名を使用）
SELECT 
  'Sample Results' as sample_type,
  COALESCE(u.name, u.email, u.id::text) as user_identifier,
  n.name as nft_name,
  dr.investment_amount,
  ROUND(dr.daily_rate * 100, 3) || '%' as daily_rate,
  ROUND(dr.reward_amount, 4) as reward_amount,
  dr.reward_date
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN users u ON un.user_id = u.id
JOIN nfts n ON un.nft_id = n.id
WHERE dr.reward_date = CURRENT_DATE
ORDER BY dr.reward_amount DESC
LIMIT 10;

-- 6. エラーチェック
SELECT 
  'Error Check' as check_type,
  CASE 
    WHEN EXISTS (SELECT 1 FROM daily_rewards WHERE reward_date = CURRENT_DATE) 
    THEN 'SUCCESS: Daily rewards calculated'
    ELSE 'ERROR: No daily rewards found'
  END as status,
  CASE 
    WHEN EXTRACT(DOW FROM CURRENT_DATE) BETWEEN 1 AND 5 
    THEN 'WEEKDAY: Calculation should work'
    ELSE 'WEEKEND: Calculation should be skipped'
  END as day_status;

-- 7. 詳細なデバッグ情報
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
WHERE week_start_date = (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 day')::DATE

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
