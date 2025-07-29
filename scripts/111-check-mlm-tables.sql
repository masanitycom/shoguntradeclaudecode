-- MLM関連テーブルの存在確認

-- 1. 現在存在するMLM関連テーブルを確認
SELECT 'Checking existing MLM tables:' as info;

SELECT table_name 
FROM information_schema.tables 
WHERE table_name IN ('mlm_ranks', 'user_rank_history', 'tenka_bonus_distributions', 'user_tenka_bonuses')
ORDER BY table_name;

-- 2. mlm_ranksテーブルの確認
SELECT 'MLM ranks table:' as info;
SELECT * FROM mlm_ranks ORDER BY rank_level;

-- 3. 不足しているテーブルがあれば確認
SELECT 'Missing tables check completed' as status;
