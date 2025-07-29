-- 完全なMLMシステムのテスト

-- 1. システム状況確認
SELECT 'System Status Check:' as info;

-- MLMランク確認
SELECT 'MLM Ranks:' as category, rank_order, rank_name, required_investment, distribution_rate 
FROM mlm_ranks ORDER BY rank_order;

-- 現在のランク保有者確認
SELECT 'Current Rank Holders:' as category, 
  u.name, u.user_id, urh.rank_name, urh.organization_volume
FROM user_rank_history urh
JOIN users u ON urh.user_id = u.id
WHERE urh.is_current = true
ORDER BY urh.rank_order DESC;

-- 2. 天下統一ボーナス分配テスト
SELECT 'Testing Tenka Bonus Distribution:' as info;

SELECT * FROM calculate_and_distribute_tenka_bonus(
  100000.00, -- 会社利益 $100,000
  '2024-01-01'::DATE, -- 週開始日
  '2024-01-07'::DATE  -- 週終了日
);

-- 3. 分配結果確認
SELECT 'Distribution Results:' as info;

-- 分配記録
SELECT 'Distribution Records:' as category,
  week_start_date, week_end_date, total_company_profit, bonus_pool, total_distributed
FROM tenka_bonus_distributions ORDER BY distribution_date DESC;

-- ユーザー別ボーナス
SELECT 'User Bonuses:' as category,
  u.name, u.user_id, utb.rank_name, utb.bonus_percentage, utb.bonus_amount
FROM user_tenka_bonuses utb
JOIN users u ON utb.user_id = u.id
ORDER BY utb.bonus_amount DESC;

-- 4. ランク更新テスト
SELECT 'Testing Rank Update:' as info;
SELECT * FROM update_all_user_ranks();

-- 5. 最終確認
SELECT 'Final System Check:' as info;

-- テーブル存在確認
SELECT 'Tables:' as category, table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('mlm_ranks', 'user_rank_history', 'tenka_bonus_distributions', 'user_tenka_bonuses')
ORDER BY table_name;

-- 関数存在確認
SELECT 'Functions:' as category, routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('calculate_organization_volume', 'determine_user_rank', 'update_all_user_ranks', 'calculate_and_distribute_tenka_bonus')
ORDER BY routine_name;

SELECT 'Complete MLM system test finished successfully' as status;
