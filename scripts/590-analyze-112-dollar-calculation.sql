-- $112.00の計算根拠を詳細分析

-- 1. $1,000投資ユーザーの日利計算履歴
SELECT 
  'Daily Calculation Breakdown' as analysis_type,
  u.name,
  dr.reward_date,
  dr.reward_amount,
  gwr.weekly_rate * 100 as weekly_rate_percent,
  CASE 
    WHEN EXTRACT(DOW FROM dr.reward_date) = 1 THEN gwr.monday_rate * 100
    WHEN EXTRACT(DOW FROM dr.reward_date) = 2 THEN gwr.tuesday_rate * 100
    WHEN EXTRACT(DOW FROM dr.reward_date) = 3 THEN gwr.wednesday_rate * 100
    WHEN EXTRACT(DOW FROM dr.reward_date) = 4 THEN gwr.thursday_rate * 100
    WHEN EXTRACT(DOW FROM dr.reward_date) = 5 THEN gwr.friday_rate * 100
  END as daily_rate_percent,
  n.price as nft_price,
  un.total_earned as cumulative_earned
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rewards dr ON dr.user_id = u.id AND dr.user_nft_id = un.id
LEFT JOIN group_weekly_rates gwr ON gwr.group_id = (
  SELECT id FROM daily_rate_groups WHERE daily_rate_limit = n.daily_rate_limit
) AND gwr.week_start_date = DATE_TRUNC('week', dr.reward_date)
WHERE n.price = 1000
  AND u.name = 'ノムラトシコ2'  -- 代表例として
  AND dr.reward_date >= '2025-06-01'
ORDER BY dr.reward_date DESC
LIMIT 20;

-- 2. $112.00の計算式確認
SELECT 
  'Calculation Formula Verification' as analysis_type,
  COUNT(dr.id) as total_reward_days,
  SUM(dr.reward_amount) as total_earned,
  AVG(dr.reward_amount) as avg_daily_reward,
  MIN(dr.reward_date) as first_reward_date,
  MAX(dr.reward_date) as last_reward_date,
  -- 理論的計算
  1000 * 0.005 as theoretical_0_5_percent,  -- 0.5%の場合
  1000 * 0.006 as theoretical_0_6_percent,  -- 0.6%の場合
  -- 実際の平均日利率
  (SUM(dr.reward_amount) / COUNT(dr.id)) / 1000 * 100 as actual_avg_daily_rate_percent
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
JOIN daily_rewards dr ON dr.user_id = u.id AND dr.user_nft_id = un.id
WHERE n.price = 1000
  AND u.name = 'ノムラトシコ2';

-- 3. 週利2.6%のランダム分配パターン確認
SELECT 
  'Weekly Distribution Pattern' as analysis_type,
  gwr.week_start_date,
  gwr.weekly_rate * 100 as weekly_rate_percent,
  gwr.monday_rate * 100 as monday_percent,
  gwr.tuesday_rate * 100 as tuesday_percent,
  gwr.wednesday_rate * 100 as wednesday_percent,
  gwr.thursday_rate * 100 as thursday_percent,
  gwr.friday_rate * 100 as friday_percent,
  (gwr.monday_rate + gwr.tuesday_rate + gwr.wednesday_rate + 
   gwr.thursday_rate + gwr.friday_rate) * 100 as total_daily_percent,
  gwr.distribution_method
FROM group_weekly_rates gwr
JOIN daily_rate_groups drg ON gwr.group_id = drg.id
WHERE drg.daily_rate_limit = 0.005  -- 0.5%グループ
  AND gwr.week_start_date >= '2025-06-01'
ORDER BY gwr.week_start_date DESC
LIMIT 10;

-- 4. システム全体の整合性確認
SELECT 
  'System Integrity Check' as check_type,
  COUNT(DISTINCT u.id) as users_with_1000_investment,
  COUNT(DISTINCT un.id) as total_1000_nfts,
  AVG(un.total_earned) as avg_earnings_1000_nfts,
  MIN(un.total_earned) as min_earnings,
  MAX(un.total_earned) as max_earnings,
  STDDEV(un.total_earned) as earnings_std_dev,
  -- 全員が同じ$112.00かチェック
  COUNT(CASE WHEN ABS(un.total_earned - 112.00) < 0.01 THEN 1 END) as users_with_exactly_112,
  COUNT(CASE WHEN un.total_earned != 112.00 THEN 1 END) as users_with_different_earnings
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
WHERE n.price = 1000
  AND un.current_investment > 0;
