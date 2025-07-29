-- 孤立レコードをクリーンアップしてから制約を追加

-- 1. 現在の状況確認
SELECT 
    'Current status' as info,
    'Orphaned user_nfts' as type,
    COUNT(*) as count
FROM user_nfts un
LEFT JOIN users u ON un.user_id = u.id
WHERE u.id IS NULL;

-- 2. 孤立したuser_nftsレコードの詳細確認（最初の10件）
SELECT 
    'Orphaned details' as info,
    un.user_id,
    un.nft_id,
    un.is_active,
    un.created_at
FROM user_nfts un
LEFT JOIN users u ON un.user_id = u.id
WHERE u.id IS NULL
ORDER BY un.created_at DESC
LIMIT 10;

-- 3. 孤立レコードを削除
DO $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- 孤立したuser_nftsレコードを削除
    DELETE FROM user_nfts 
    WHERE user_id NOT IN (SELECT id FROM users);
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % orphaned user_nfts records', deleted_count;
END $$;

-- 4. 削除後の確認
SELECT 
    'After cleanup' as info,
    'Remaining orphaned user_nfts' as type,
    COUNT(*) as count
FROM user_nfts un
LEFT JOIN users u ON un.user_id = u.id
WHERE u.id IS NULL;

-- 5. user_nfts_user_id_fkey制約を追加
DO $$
BEGIN
    -- 既存の制約を確認
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE constraint_name = 'user_nfts_user_id_fkey'
        AND table_schema = 'public'
        AND table_name = 'user_nfts'
    ) THEN
        -- 制約を追加
        ALTER TABLE user_nfts 
        ADD CONSTRAINT user_nfts_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        
        RAISE NOTICE 'Successfully added user_nfts_user_id_fkey constraint';
    ELSE
        RAISE NOTICE 'user_nfts_user_id_fkey constraint already exists';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Failed to add user_nfts_user_id_fkey constraint: %', SQLERRM;
END $$;

-- 6. 制約追加後の確認
SELECT 
    'Constraint verification' as info,
    constraint_name,
    table_name,
    'ACTIVE' as status
FROM information_schema.table_constraints
WHERE constraint_type = 'FOREIGN KEY'
AND table_schema = 'public'
AND table_name = 'user_nfts'
ORDER BY constraint_name;

-- 7. 全体の制約確認
SELECT 
    'All constraints summary' as check_type,
    table_name,
    COUNT(*) as constraint_count
FROM information_schema.table_constraints
WHERE constraint_type = 'FOREIGN KEY'
AND table_schema = 'public'
AND table_name IN ('user_nfts', 'nft_purchase_applications', 'reward_applications', 'user_rank_history', 'tenka_bonus_distributions', 'daily_rewards', 'users')
GROUP BY table_name
ORDER BY table_name;

-- 8. 最終統計
SELECT 
    'Final statistics' as info,
    'Total users' as metric,
    COUNT(*) as count
FROM users
UNION ALL
SELECT 
    'Final statistics' as info,
    'Active NFTs' as metric,
    COUNT(*) as count
FROM user_nfts
WHERE is_active = true
UNION ALL
SELECT 
    'Final statistics' as info,
    'Total user_nfts records' as metric,
    COUNT(*) as count
FROM user_nfts
UNION ALL
SELECT 
    'Final statistics' as info,
    'Foreign key constraints' as metric,
    COUNT(*) as count
FROM information_schema.table_constraints
WHERE constraint_type = 'FOREIGN KEY'
AND table_schema = 'public';

-- 9. admin001の最終確認
SELECT 
    'admin001 final check' as info,
    id,
    user_id,
    email,
    is_admin,
    created_at
FROM users
WHERE email = 'admin@shogun-trade.com';

-- 10. 1人1枚制限の確認
SELECT 
    'Multiple NFT check' as info,
    user_id,
    COUNT(*) as nft_count
FROM user_nfts
WHERE is_active = true
GROUP BY user_id
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;
