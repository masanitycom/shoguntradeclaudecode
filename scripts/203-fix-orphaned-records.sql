-- 孤立レコード修正スクリプト

-- 1. 現在の状況確認
SELECT 
    'Current status - auth.users' as table_name,
    COUNT(*) as count
FROM auth.users
UNION ALL
SELECT 
    'Current status - public.users' as table_name,
    COUNT(*) as count
FROM public.users
UNION ALL
SELECT 
    'Active user_nfts' as table_name,
    COUNT(*) as count
FROM user_nfts
WHERE is_active = true;

-- 2. 孤立したuser_nftsレコードを特定
SELECT 
    'Orphaned user_nfts records' as issue_type,
    COUNT(*) as count
FROM user_nfts un
LEFT JOIN users u ON un.user_id = u.id
WHERE u.id IS NULL;

-- 3. 孤立したuser_nftsの詳細確認
SELECT 
    'Orphaned NFT details' as info,
    un.user_id,
    un.nft_id,
    un.is_active,
    un.created_at
FROM user_nfts un
LEFT JOIN users u ON un.user_id = u.id
WHERE u.id IS NULL
ORDER BY un.created_at
LIMIT 10;

-- 4. 孤立したレコードを修正
DO $$
DECLARE
    orphan_record RECORD;
    auth_user_exists BOOLEAN;
    new_user_counter INTEGER := 1;
    new_user_id TEXT;
    max_user_num INTEGER;
BEGIN
    RAISE NOTICE 'Starting orphaned records fix...';
    
    -- 既存の最大USER番号を取得
    SELECT COALESCE(MAX(CAST(SUBSTRING(user_id FROM 5) AS INTEGER)), 0) + 1
    INTO max_user_num
    FROM users 
    WHERE user_id ~ '^USER[0-9]+$';
    
    new_user_counter := GREATEST(max_user_num, 1);
    
    -- 孤立したuser_nftsレコードを処理
    FOR orphan_record IN 
        SELECT DISTINCT un.user_id
        FROM user_nfts un
        LEFT JOIN users u ON un.user_id = u.id
        WHERE u.id IS NULL
    LOOP
        RAISE NOTICE 'Processing orphaned user_id: %', orphan_record.user_id;
        
        -- auth.usersに存在するかチェック
        SELECT EXISTS(
            SELECT 1 FROM auth.users WHERE id = orphan_record.user_id
        ) INTO auth_user_exists;
        
        IF auth_user_exists THEN
            -- auth.usersに存在する場合、public.usersに追加
            new_user_id := 'USER' || LPAD(new_user_counter::text, 3, '0');
            
            -- user_idの重複チェック
            WHILE EXISTS (SELECT 1 FROM users WHERE user_id = new_user_id) LOOP
                new_user_counter := new_user_counter + 1;
                new_user_id := 'USER' || LPAD(new_user_counter::text, 3, '0');
            END LOOP;
            
            INSERT INTO public.users (
                id,
                name,
                email,
                user_id,
                phone,
                my_referral_code,
                referral_link,
                created_at,
                updated_at,
                is_admin,
                usdt_address,
                wallet_type,
                password_changed
            )
            SELECT 
                au.id,
                split_part(au.email, '@', 1),
                au.email,
                new_user_id,
                '',
                'REF' || UPPER(substring(md5(au.id::text) from 1 for 8)),
                'https://shogun-trade.vercel.app/register?ref=' || 'REF' || UPPER(substring(md5(au.id::text) from 1 for 8)),
                au.created_at,
                NOW(),
                CASE WHEN au.email = 'admin@shogun-trade.com' THEN true ELSE false END,
                NULL,
                NULL,
                false
            FROM auth.users au
            WHERE au.id = orphan_record.user_id;
            
            new_user_counter := new_user_counter + 1;
            
            RAISE NOTICE 'Created missing user: % with user_id: %', 
                orphan_record.user_id, new_user_id;
        ELSE
            -- auth.usersにも存在しない場合、NFTを非アクティブ化
            UPDATE user_nfts 
            SET is_active = false,
                updated_at = NOW()
            WHERE user_id = orphan_record.user_id;
            
            RAISE NOTICE 'Deactivated NFTs for non-existent user: %', orphan_record.user_id;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Orphaned records fix completed';
END $$;

-- 5. 他の孤立レコードも修正（テーブル構造を確認してから実行）
DO $$
DECLARE
    orphan_count INTEGER;
    table_exists BOOLEAN;
    column_exists BOOLEAN;
BEGIN
    -- nft_purchase_applications
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'nft_purchase_applications'
    ) INTO table_exists;
    
    IF table_exists THEN
        SELECT COUNT(*) INTO orphan_count
        FROM nft_purchase_applications npa
        LEFT JOIN users u ON npa.user_id = u.id
        WHERE u.id IS NULL;
        
        IF orphan_count > 0 THEN
            DELETE FROM nft_purchase_applications
            WHERE user_id NOT IN (SELECT id FROM users);
            RAISE NOTICE 'Deleted % orphaned nft_purchase_applications', orphan_count;
        END IF;
    END IF;
    
    -- reward_applications
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'reward_applications'
    ) INTO table_exists;
    
    IF table_exists THEN
        SELECT COUNT(*) INTO orphan_count
        FROM reward_applications ra
        LEFT JOIN users u ON ra.user_id = u.id
        WHERE u.id IS NULL;
        
        IF orphan_count > 0 THEN
            DELETE FROM reward_applications
            WHERE user_id NOT IN (SELECT id FROM users);
            RAISE NOTICE 'Deleted % orphaned reward_applications', orphan_count;
        END IF;
    END IF;
    
    -- user_rank_history
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'user_rank_history'
    ) INTO table_exists;
    
    IF table_exists THEN
        SELECT COUNT(*) INTO orphan_count
        FROM user_rank_history urh
        LEFT JOIN users u ON urh.user_id = u.id
        WHERE u.id IS NULL;
        
        IF orphan_count > 0 THEN
            DELETE FROM user_rank_history
            WHERE user_id NOT IN (SELECT id FROM users);
            RAISE NOTICE 'Deleted % orphaned user_rank_history', orphan_count;
        END IF;
    END IF;
    
    -- tenka_bonus_distributions
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'tenka_bonus_distributions'
    ) INTO table_exists;
    
    IF table_exists THEN
        SELECT COUNT(*) INTO orphan_count
        FROM tenka_bonus_distributions tbd
        LEFT JOIN users u ON tbd.user_id = u.id
        WHERE u.id IS NULL;
        
        IF orphan_count > 0 THEN
            DELETE FROM tenka_bonus_distributions
            WHERE user_id NOT IN (SELECT id FROM users);
            RAISE NOTICE 'Deleted % orphaned tenka_bonus_distributions', orphan_count;
        END IF;
    END IF;
    
    -- daily_rewards（カラム名を確認）
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'daily_rewards'
    ) INTO table_exists;
    
    IF table_exists THEN
        -- user_idカラムの存在確認
        SELECT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'daily_rewards' 
            AND column_name = 'user_id'
        ) INTO column_exists;
        
        IF column_exists THEN
            SELECT COUNT(*) INTO orphan_count
            FROM daily_rewards dr
            LEFT JOIN users u ON dr.user_id = u.id
            WHERE u.id IS NULL;
            
            IF orphan_count > 0 THEN
                DELETE FROM daily_rewards
                WHERE user_id NOT IN (SELECT id FROM users);
                RAISE NOTICE 'Deleted % orphaned daily_rewards', orphan_count;
            END IF;
        ELSE
            RAISE NOTICE 'daily_rewards table exists but user_id column not found';
        END IF;
    END IF;
    
    -- 紹介関係の修正
    UPDATE users 
    SET referrer_id = NULL 
    WHERE referrer_id IS NOT NULL 
    AND referrer_id NOT IN (SELECT id FROM users);
    
    -- processed_by の修正
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'nft_purchase_applications' 
        AND column_name = 'processed_by'
    ) INTO column_exists;
    
    IF column_exists THEN
        UPDATE nft_purchase_applications 
        SET processed_by = NULL 
        WHERE processed_by IS NOT NULL 
        AND processed_by NOT IN (SELECT id FROM users);
    END IF;
    
    RAISE NOTICE 'All orphaned records cleaned up';
END $$;

-- 6. 外部キー制約を段階的に再作成
DO $$
BEGIN
    -- user_nfts
    BEGIN
        ALTER TABLE user_nfts 
        ADD CONSTRAINT user_nfts_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_nfts foreign key constraint';
    EXCEPTION WHEN duplicate_object THEN
        RAISE NOTICE 'user_nfts constraint already exists';
    WHEN OTHERS THEN
        RAISE NOTICE 'Failed to add user_nfts constraint: %', SQLERRM;
    END;
    
    -- nft_purchase_applications
    BEGIN
        ALTER TABLE nft_purchase_applications 
        ADD CONSTRAINT nft_purchase_applications_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added nft_purchase_applications user_id constraint';
    EXCEPTION WHEN duplicate_object THEN
        RAISE NOTICE 'nft_purchase_applications user_id constraint already exists';
    WHEN OTHERS THEN
        RAISE NOTICE 'Failed to add nft_purchase_applications user_id constraint: %', SQLERRM;
    END;
    
    -- reward_applications
    BEGIN
        ALTER TABLE reward_applications 
        ADD CONSTRAINT reward_applications_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added reward_applications constraint';
    EXCEPTION WHEN duplicate_object THEN
        RAISE NOTICE 'reward_applications constraint already exists';
    WHEN OTHERS THEN
        RAISE NOTICE 'Failed to add reward_applications constraint: %', SQLERRM;
    END;
    
    -- user_rank_history
    BEGIN
        ALTER TABLE user_rank_history 
        ADD CONSTRAINT user_rank_history_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added user_rank_history constraint';
    EXCEPTION WHEN duplicate_object THEN
        RAISE NOTICE 'user_rank_history constraint already exists';
    WHEN OTHERS THEN
        RAISE NOTICE 'Failed to add user_rank_history constraint: %', SQLERRM;
    END;
    
    -- tenka_bonus_distributions
    BEGIN
        ALTER TABLE tenka_bonus_distributions 
        ADD CONSTRAINT tenka_bonus_distributions_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added tenka_bonus_distributions constraint';
    EXCEPTION WHEN duplicate_object THEN
        RAISE NOTICE 'tenka_bonus_distributions constraint already exists';
    WHEN OTHERS THEN
        RAISE NOTICE 'Failed to add tenka_bonus_distributions constraint: %', SQLERRM;
    END;
    
    -- daily_rewards（テーブルとカラムの存在確認）
    BEGIN
        IF EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'daily_rewards' 
            AND column_name = 'user_id'
        ) THEN
            ALTER TABLE daily_rewards 
            ADD CONSTRAINT daily_rewards_user_id_fkey 
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
            RAISE NOTICE 'Added daily_rewards constraint';
        ELSE
            RAISE NOTICE 'daily_rewards table or user_id column not found';
        END IF;
    EXCEPTION WHEN duplicate_object THEN
        RAISE NOTICE 'daily_rewards constraint already exists';
    WHEN OTHERS THEN
        RAISE NOTICE 'Failed to add daily_rewards constraint: %', SQLERRM;
    END;
    
    -- users referrer_id
    BEGIN
        ALTER TABLE users 
        ADD CONSTRAINT users_referrer_id_fkey 
        FOREIGN KEY (referrer_id) REFERENCES users(id) ON DELETE SET NULL;
        RAISE NOTICE 'Added users referrer_id constraint';
    EXCEPTION WHEN duplicate_object THEN
        RAISE NOTICE 'users referrer_id constraint already exists';
    WHEN OTHERS THEN
        RAISE NOTICE 'Failed to add users referrer_id constraint: %', SQLERRM;
    END;
    
    -- nft_purchase_applications processed_by
    BEGIN
        IF EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'nft_purchase_applications' 
            AND column_name = 'processed_by'
        ) THEN
            ALTER TABLE nft_purchase_applications 
            ADD CONSTRAINT nft_purchase_applications_processed_by_fkey 
            FOREIGN KEY (processed_by) REFERENCES users(id) ON DELETE SET NULL;
            RAISE NOTICE 'Added nft_purchase_applications processed_by constraint';
        ELSE
            RAISE NOTICE 'nft_purchase_applications processed_by column not found';
        END IF;
    EXCEPTION WHEN duplicate_object THEN
        RAISE NOTICE 'nft_purchase_applications processed_by constraint already exists';
    WHEN OTHERS THEN
        RAISE NOTICE 'Failed to add nft_purchase_applications processed_by constraint: %', SQLERRM;
    END;
END $$;

-- 7. 1人1枚制限のトリガーを再作成
DO $$
BEGIN
    -- 既存のトリガーを削除
    DROP TRIGGER IF EXISTS trigger_one_nft_per_user ON user_nfts;
    
    -- トリガーを再作成
    CREATE TRIGGER trigger_one_nft_per_user
        BEFORE INSERT OR UPDATE ON user_nfts
        FOR EACH ROW
        EXECUTE FUNCTION check_one_nft_per_user();
    
    RAISE NOTICE 'Recreated one NFT per user trigger';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Failed to recreate trigger: %', SQLERRM;
END $$;

-- 8. 最終確認
SELECT 
    'Final verification - auth.users' as table_name,
    COUNT(*) as count
FROM auth.users
UNION ALL
SELECT 
    'Final verification - public.users' as table_name,
    COUNT(*) as count
FROM public.users
UNION ALL
SELECT 
    'Perfect ID matches' as table_name,
    COUNT(*) as count
FROM auth.users au
INNER JOIN public.users pu ON au.id = pu.id
UNION ALL
SELECT 
    'Email mismatches remaining' as table_name,
    COUNT(*) as count
FROM auth.users au
INNER JOIN public.users pu ON au.email = pu.email
WHERE au.id != pu.id
UNION ALL
SELECT 
    'Active NFTs' as table_name,
    COUNT(*) as count
FROM user_nfts
WHERE is_active = true
UNION ALL
SELECT 
    'Users with multiple NFTs' as table_name,
    COUNT(*) as count
FROM (
    SELECT user_id
    FROM user_nfts 
    WHERE is_active = true 
    GROUP BY user_id 
    HAVING COUNT(*) > 1
) multi_nft_users;

-- 9. admin001の最終確認
SELECT 
    'admin001 final status' as check_type,
    u.id,
    u.user_id,
    u.email,
    u.is_admin,
    CASE 
        WHEN EXISTS(SELECT 1 FROM auth.users WHERE id = u.id) THEN 'AUTH_SYNCED'
        ELSE 'AUTH_MISSING'
    END as auth_status
FROM users u
WHERE u.email = 'admin@shogun-trade.com';

-- 10. 制約確認
SELECT 
    'Foreign key constraints' as check_type,
    constraint_name,
    table_name,
    'ACTIVE' as status
FROM information_schema.table_constraints
WHERE constraint_type = 'FOREIGN KEY'
AND table_schema = 'public'
AND table_name IN ('user_nfts', 'nft_purchase_applications', 'reward_applications', 'user_rank_history', 'tenka_bonus_distributions', 'daily_rewards', 'users')
ORDER BY table_name, constraint_name;

-- 11. 孤立レコード最終確認
SELECT 
    'Final orphaned check - user_nfts' as check_type,
    COUNT(*) as count
FROM user_nfts un
LEFT JOIN users u ON un.user_id = u.id
WHERE u.id IS NULL AND un.is_active = true;
