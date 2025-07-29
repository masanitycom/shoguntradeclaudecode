-- 緊急ユーザー同期修正スクリプト（重複キー完全回避版）

-- 1. 現在の状況を詳細確認
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
    'ID matches' as table_name,
    COUNT(*) as count
FROM auth.users au
INNER JOIN public.users pu ON au.id = pu.id
UNION ALL
SELECT 
    'Email matches with different IDs' as table_name,
    COUNT(*) as count
FROM auth.users au
INNER JOIN public.users pu ON au.email = pu.email
WHERE au.id != pu.id;

-- 2. 問題のあるレコードを特定（一時テーブル作成を修正）
DO $$
BEGIN
    -- 既存の一時テーブルを削除
    DROP TABLE IF EXISTS problematic_users;
    
    -- 一時テーブルを作成
    CREATE TEMP TABLE problematic_users AS
    SELECT 
        au.id as auth_id,
        au.email as auth_email,
        au.created_at as auth_created,
        pu.id as public_id,
        pu.email as public_email,
        pu.user_id as public_user_id,
        pu.created_at as public_created,
        pu.name as public_name,
        pu.phone as public_phone,
        pu.my_referral_code as public_referral_code,
        pu.referral_link as public_referral_link,
        pu.is_admin as public_is_admin,
        pu.referrer_id as public_referrer_id,
        pu.usdt_address as public_usdt_address,
        pu.wallet_type as public_wallet_type,
        pu.password_changed as public_password_changed
    FROM auth.users au
    INNER JOIN public.users pu ON au.email = pu.email
    WHERE au.id != pu.id;
    
    RAISE NOTICE '問題のあるレコードを特定しました';
END $$;

-- 3. 問題のあるレコード数を確認
SELECT 'Problematic records count' as info, COUNT(*) as count FROM problematic_users;

-- 4. 1人1枚制限のトリガーを一時的に無効化
DO $$
BEGIN
    DROP TRIGGER IF EXISTS trigger_one_nft_per_user ON user_nfts;
    RAISE NOTICE '1人1枚制限トリガーを一時的に無効化しました';
END $$;

-- 5. 外部キー制約を一時的に削除
DO $$
DECLARE
    constraint_record RECORD;
BEGIN
    FOR constraint_record IN 
        SELECT 
            tc.table_name,
            tc.constraint_name
        FROM information_schema.table_constraints AS tc 
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY' 
        AND tc.table_schema = 'public'
        AND ccu.table_name = 'users'
    LOOP
        EXECUTE format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS %I', 
                      constraint_record.table_name, 
                      constraint_record.constraint_name);
        RAISE NOTICE 'Dropped constraint: %.%', 
                     constraint_record.table_name, 
                     constraint_record.constraint_name;
    END LOOP;
END $$;

-- 6. 段階的な安全な統合処理
DO $$
DECLARE
    problem_user RECORD;
    new_user_counter INTEGER := 1;
    new_user_id TEXT;
    max_user_num INTEGER;
BEGIN
    RAISE NOTICE 'Starting emergency user sync fix...';
    
    -- 既存の最大USER番号を取得
    SELECT COALESCE(MAX(CAST(SUBSTRING(user_id FROM 5) AS INTEGER)), 0) + 1
    INTO max_user_num
    FROM users 
    WHERE user_id ~ '^USER[0-9]+$';
    
    new_user_counter := GREATEST(max_user_num, 1);
    
    -- 問題のあるユーザーを1つずつ処理
    FOR problem_user IN SELECT * FROM problematic_users ORDER BY auth_created LOOP
        RAISE NOTICE 'Processing user: % (auth_id: %, public_id: %)', 
            problem_user.auth_email, problem_user.auth_id, problem_user.public_id;
        
        -- Step 1: 関連データをauth_idに移行
        BEGIN
            -- user_nftsテーブル（重複チェック付き）
            UPDATE user_nfts 
            SET user_id = problem_user.auth_id 
            WHERE user_id = problem_user.public_id
            AND NOT EXISTS (
                SELECT 1 FROM user_nfts 
                WHERE user_id = problem_user.auth_id 
                AND is_active = true
            );
            
            -- 重複がある場合は古いNFTを非アクティブ化
            UPDATE user_nfts 
            SET is_active = false 
            WHERE user_id = problem_user.public_id
            AND EXISTS (
                SELECT 1 FROM user_nfts 
                WHERE user_id = problem_user.auth_id 
                AND is_active = true
            );
            
            -- その他の関連テーブル
            UPDATE nft_purchase_applications 
            SET user_id = problem_user.auth_id 
            WHERE user_id = problem_user.public_id;
            
            UPDATE reward_applications 
            SET user_id = problem_user.auth_id 
            WHERE user_id = problem_user.public_id;
            
            UPDATE user_rank_history 
            SET user_id = problem_user.auth_id 
            WHERE user_id = problem_user.public_id;
            
            UPDATE tenka_bonus_distributions 
            SET user_id = problem_user.auth_id 
            WHERE user_id = problem_user.public_id;
            
            UPDATE daily_rewards 
            SET user_id = problem_user.auth_id 
            WHERE user_id = problem_user.public_id;
            
            -- 紹介関係の更新
            UPDATE users 
            SET referrer_id = problem_user.auth_id 
            WHERE referrer_id = problem_user.public_id;
            
            RAISE NOTICE 'Updated related data for user: %', problem_user.auth_email;
            
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error updating related data for %: %', problem_user.auth_email, SQLERRM;
        END;
        
        -- Step 2: 古いpublic.usersレコードを削除
        DELETE FROM users WHERE id = problem_user.public_id;
        RAISE NOTICE 'Deleted old public.users record for: %', problem_user.auth_email;
        
        -- Step 3: 新しいpublic.usersレコードを作成（auth_idが既に存在しない場合のみ）
        IF NOT EXISTS (SELECT 1 FROM users WHERE id = problem_user.auth_id) THEN
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
                referrer_id,
                usdt_address,
                wallet_type,
                password_changed
            ) VALUES (
                problem_user.auth_id,
                COALESCE(problem_user.public_name, split_part(problem_user.auth_email, '@', 1)),
                problem_user.auth_email,
                problem_user.public_user_id,
                COALESCE(problem_user.public_phone, ''),
                COALESCE(problem_user.public_referral_code, 'REF' || UPPER(substring(md5(problem_user.auth_id::text) from 1 for 8))),
                COALESCE(problem_user.public_referral_link, 'https://shogun-trade.vercel.app/register?ref=' || COALESCE(problem_user.public_referral_code, 'REF' || UPPER(substring(md5(problem_user.auth_id::text) from 1 for 8)))),
                problem_user.auth_created,
                NOW(),
                COALESCE(problem_user.public_is_admin, CASE WHEN problem_user.auth_email = 'admin@shogun-trade.com' THEN true ELSE false END),
                problem_user.public_referrer_id,
                problem_user.public_usdt_address,
                problem_user.public_wallet_type,
                COALESCE(problem_user.public_password_changed, false)
            );
            
            RAISE NOTICE 'Created new public.users record for: % with user_id: %', 
                problem_user.auth_email, problem_user.public_user_id;
        ELSE
            RAISE NOTICE 'Auth ID already exists in public.users, skipping insert for: %', problem_user.auth_email;
        END IF;
        
    END LOOP;
    
    -- Step 4: auth.usersに存在するがpublic.usersに存在しないユーザーを追加
    FOR problem_user IN 
        SELECT au.id, au.email, au.created_at
        FROM auth.users au
        LEFT JOIN public.users pu ON au.id = pu.id
        WHERE pu.id IS NULL
    LOOP
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
        ) VALUES (
            problem_user.id,
            split_part(problem_user.email, '@', 1),
            problem_user.email,
            new_user_id,
            '',
            'REF' || UPPER(substring(md5(problem_user.id::text) from 1 for 8)),
            'https://shogun-trade.vercel.app/register?ref=' || 'REF' || UPPER(substring(md5(problem_user.id::text) from 1 for 8)),
            problem_user.created_at,
            NOW(),
            CASE WHEN problem_user.email = 'admin@shogun-trade.com' THEN true ELSE false END,
            NULL,
            NULL,
            false
        );
        
        new_user_counter := new_user_counter + 1;
        
        RAISE NOTICE 'Added missing user: % with user_id: %', 
            problem_user.email, new_user_id;
    END LOOP;
    
    RAISE NOTICE 'Emergency user sync fix completed successfully';
END $$;

-- 7. 外部キー制約を再作成
DO $$
BEGIN
    -- user_nftsテーブル
    ALTER TABLE user_nfts 
    ADD CONSTRAINT user_nfts_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    
    -- nft_purchase_applicationsテーブル
    ALTER TABLE nft_purchase_applications 
    ADD CONSTRAINT nft_purchase_applications_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    
    -- reward_applicationsテーブル
    ALTER TABLE reward_applications 
    ADD CONSTRAINT reward_applications_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    
    -- user_rank_historyテーブル
    ALTER TABLE user_rank_history 
    ADD CONSTRAINT user_rank_history_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    
    -- tenka_bonus_distributionsテーブル
    ALTER TABLE tenka_bonus_distributions 
    ADD CONSTRAINT tenka_bonus_distributions_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    
    -- daily_rewardsテーブル
    ALTER TABLE daily_rewards 
    ADD CONSTRAINT daily_rewards_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    
    -- usersテーブルのreferrer_id
    ALTER TABLE users 
    ADD CONSTRAINT users_referrer_id_fkey 
    FOREIGN KEY (referrer_id) REFERENCES users(id) ON DELETE SET NULL;
    
    -- processed_by制約
    ALTER TABLE nft_purchase_applications 
    ADD CONSTRAINT nft_purchase_applications_processed_by_fkey 
    FOREIGN KEY (processed_by) REFERENCES users(id) ON DELETE SET NULL;
    
    RAISE NOTICE 'Foreign key constraints recreated successfully';
END $$;

-- 8. 1人1枚制限のトリガーを再作成
DO $$
BEGIN
    CREATE TRIGGER trigger_one_nft_per_user
        BEFORE INSERT OR UPDATE ON user_nfts
        FOR EACH ROW
        EXECUTE FUNCTION check_one_nft_per_user();
    RAISE NOTICE '1人1枚制限トリガーを再作成しました';
END $$;

-- 9. 最終結果確認
SELECT 
    'Final status - auth.users' as table_name,
    COUNT(*) as count
FROM auth.users
UNION ALL
SELECT 
    'Final status - public.users' as table_name,
    COUNT(*) as count
FROM public.users
UNION ALL
SELECT 
    'Perfect matches (ID)' as table_name,
    COUNT(*) as count
FROM auth.users au
INNER JOIN public.users pu ON au.id = pu.id
UNION ALL
SELECT 
    'Email matches with different IDs' as table_name,
    COUNT(*) as count
FROM auth.users au
INNER JOIN public.users pu ON au.email = pu.email
WHERE au.id != pu.id;

-- 10. admin001の最終確認
SELECT 
    'admin001 final check' as check_type,
    au.id as auth_id,
    pu.id as public_id,
    pu.user_id as user_id,
    pu.is_admin,
    CASE WHEN au.id = pu.id THEN 'PERFECT_MATCH' ELSE 'STILL_MISMATCH' END as status
FROM auth.users au
FULL OUTER JOIN public.users pu ON au.email = pu.email
WHERE au.email = 'admin@shogun-trade.com' OR pu.email = 'admin@shogun-trade.com';

-- 11. 1人1枚制限の最終確認
SELECT 
    'NFT ownership final check' as check_type,
    user_id,
    COUNT(*) as active_nft_count
FROM user_nfts 
WHERE is_active = true 
GROUP BY user_id 
HAVING COUNT(*) > 1
ORDER BY active_nft_count DESC;

-- 12. 一時テーブルをクリーンアップ
DROP TABLE IF EXISTS problematic_users;
