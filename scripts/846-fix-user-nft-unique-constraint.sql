-- user_nfts一意制約問題の修正

SELECT '=== user_nfts一意制約問題修正 ===' as section;

-- 1. 問題の確認：user_nfts_user_nft_uniqueが(user_id, nft_id)の複合一意制約になっている
SELECT '現在の一意制約確認:' as constraint_check;
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    array_agg(kcu.column_name ORDER BY kcu.ordinal_position) as columns
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'user_nfts'
  AND tc.constraint_type = 'UNIQUE'
GROUP BY tc.constraint_name, tc.constraint_type;

-- 2. 制約削除（複合一意制約を削除）
SELECT '複合一意制約削除中...' as action;
ALTER TABLE user_nfts DROP CONSTRAINT IF EXISTS user_nfts_user_nft_unique;

-- 3. 正しい制約を追加（1ユーザー1NFT制限）
SELECT '正しい制約追加中...' as new_constraint;
-- 1人のユーザーは同時に1つのアクティブなNFTのみ保有可能
CREATE UNIQUE INDEX IF NOT EXISTS user_nfts_one_active_per_user 
ON user_nfts (user_id) 
WHERE is_active = true;

-- 4. 制約確認
SELECT '修正後の制約確認:' as final_check;
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    array_agg(kcu.column_name ORDER BY kcu.ordinal_position) as columns
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'user_nfts'
  AND tc.constraint_type = 'UNIQUE'
GROUP BY tc.constraint_name, tc.constraint_type;

-- 5. インデックス確認
SELECT 'インデックス確認:' as index_check;
SELECT 
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'user_nfts'
  AND indexname LIKE '%unique%' OR indexname LIKE '%active%';

SELECT '=== 制約修正完了 ===' as status;