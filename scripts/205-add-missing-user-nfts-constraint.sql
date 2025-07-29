-- user_nfts_user_id_fkey制約を追加

-- 1. 現在の制約状況確認
SELECT 
    'Current constraints check' as info,
    constraint_name,
    table_name
FROM information_schema.table_constraints
WHERE constraint_type = 'FOREIGN KEY'
AND table_schema = 'public'
AND table_name = 'user_nfts'
ORDER BY constraint_name;

-- 2. user_nfts_user_id_fkey制約の存在確認
SELECT 
    'user_nfts_user_id_fkey exists' as check_type,
    EXISTS(
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE constraint_name = 'user_nfts_user_id_fkey'
        AND table_schema = 'public'
        AND table_name = 'user_nfts'
    ) as exists;

-- 3. 孤立レコードの最終確認
SELECT 
    'Orphaned user_nfts before constraint' as check_type,
    COUNT(*) as count
FROM user_nfts un
LEFT JOIN users u ON un.user_id = u.id
WHERE u.id IS NULL;

-- 4. user_nfts_user_id_fkey制約を追加
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
        
        RAISE NOTICE 'Added user_nfts_user_id_fkey constraint successfully';
    ELSE
        RAISE NOTICE 'user_nfts_user_id_fkey constraint already exists';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Failed to add user_nfts_user_id_fkey constraint: %', SQLERRM;
END $$;

-- 5. 制約追加後の確認
SELECT 
    'Final constraints check' as info,
    constraint_name,
    table_name,
    'ACTIVE' as status
FROM information_schema.table_constraints
WHERE constraint_type = 'FOREIGN KEY'
AND table_schema = 'public'
AND table_name = 'user_nfts'
ORDER BY constraint_name;

-- 6. 全体の制約確認
SELECT 
    'All foreign key constraints' as check_type,
    table_name,
    COUNT(*) as constraint_count
FROM information_schema.table_constraints
WHERE constraint_type = 'FOREIGN KEY'
AND table_schema = 'public'
AND table_name IN ('user_nfts', 'nft_purchase_applications', 'reward_applications', 'user_rank_history', 'tenka_bonus_distributions', 'daily_rewards', 'users')
GROUP BY table_name
ORDER BY table_name;

-- 7. 最終統計
SELECT 
    'Final sync statistics' as info,
    'auth.users' as table_name,
    COUNT(*) as count
FROM auth.users
UNION ALL
SELECT 
    'Final sync statistics' as info,
    'public.users' as table_name,
    COUNT(*) as count
FROM public.users
UNION ALL
SELECT 
    'Final sync statistics' as info,
    'Perfect ID matches' as table_name,
    COUNT(*) as count
FROM auth.users au
INNER JOIN public.users pu ON au.id = pu.id
UNION ALL
SELECT 
    'Final sync statistics' as info,
    'Active NFTs' as table_name,
    COUNT(*) as count
FROM user_nfts
WHERE is_active = true;
