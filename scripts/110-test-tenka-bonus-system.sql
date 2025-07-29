-- 天下統一ボーナスシステムのテスト

-- 1. 現在のシステム状況を確認
SELECT 'Current system status:' as info;

-- ランク保有者確認
SELECT 
  'Current rank holders:' as category,
  u.name,
  u.user_id,
  urh.rank_name,
  mr.bonus_percentage
FROM user_rank_history urh
JOIN users u ON urh.user_id = u.id
JOIN mlm_ranks mr ON urh.rank_level = mr.rank_level
WHERE urh.is_current = true AND urh.rank_level > 0
ORDER BY urh.rank_level DESC;

-- 2. テスト用ボーナス分配を実行
SELECT 'Testing bonus distribution...' as info;

SELECT * FROM calculate_and_distribute_tenka_bonus(
  100000.00, -- 会社利益 $100,000
  '2024-01-01'::DATE, -- 週開始日
  '2024-01-07'::DATE  -- 週終了日
);

-- 3. 分配結果を確認
SELECT 'Distribution results:' as info;

-- 分配記録確認
SELECT 
  'Distribution records:' as category,
  week_start_date,
  week_end_date,
  total_company_profit,
  bonus_pool,
  total_distributed,
  distribution_date
FROM tenka_bonus_distributions
ORDER BY distribution_date DESC;

-- ユーザー別ボーナス確認
SELECT 
  'User bonuses:' as category,
  u.name,
  u.user_id,
  utb.rank_name,
  utb.bonus_percentage,
  utb.bonus_amount
FROM user_tenka_bonuses utb
JOIN users u ON utb.user_id = u.id
ORDER BY utb.bonus_amount DESC;

-- 4. 統計情報確認
SELECT 'System statistics:' as info;
SELECT * FROM get_tenka_bonus_stats();

-- 5. weekly_profitsテーブル確認
SELECT 'Weekly profits table:' as info;
SELECT * FROM weekly_profits ORDER BY week_start_date DESC;

SELECT 'Tenka bonus system test completed successfully' as status;
