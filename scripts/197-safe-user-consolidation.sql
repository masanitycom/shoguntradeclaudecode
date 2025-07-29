-- 安全なユーザー統合スクリプト（重複キー回避版）

-- 1. 現在の状況を確認
SELECT 
    'Before consolidation - auth.users' as table_name,
    COUNT(*) as count
FROM auth.users
UNION ALL
SELECT 
    'Before consolidation - public.users' as table_name,
    COUNT(*) as count
FROM public.users;

-- 2. 1人1枚制限のトリガーを一時的に無効化
DO $$
BEGIN
    DROP TRIGGER IF EXISTS trigger_one_nft_per_user ON user_nfts;
    RAISE NOTICE '1人1枚制限トリガーを一時的に無効化しました';
END $$;

-- 3. 外部キー制約を一時的に削除
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

-- 4. 安全なユーザー統合処理
DO $$
DECLARE
    conflict_record RECORD;
    new_user_counter INTEGER := 1;
    new_user_id TEXT;
    max_user_num INTEGER;
    temp_user_id TEXT;
BEGIN
    RAISE NOTICE 'Starting safe user consolidation...';
    
    -- 既存の最大USER番号を取得
    SELECT COALESCE(MAX(CAST(SUBSTRING(user_id FROM 5) AS INTEGER)), 0) + 1
    INTO max_user_num
    FROM users 
    WHERE user_id ~ '^USER[0-9]+$';
    
    new_user_counter := GREATEST(max_user_num, 1);
    
    -- Step 1: メールアドレスが同じだがIDが異なるケースを処理
    FOR conflict_record IN 
        SELECT 
            au.id as auth_id,
            au.email,
            au.created_at as auth_created_at,
            pu.id as public_id,
            pu.created_at as public_created_at,
            pu.user_id as old_user_id,
            pu.name as old_name,
            pu.phone as old_phone,
            pu.my_referral_code as old_referral_code,
            pu.referral_link as old_referral_link,
            pu.is_admin as old_is_admin,
            pu.referrer_id as old_referrer_id,
            pu.usdt_address as old_usdt_address,
            pu.wallet_type as old_wallet_type,
            pu.password_changed as old_password_changed
        FROM auth.users au
        INNER JOIN public.users pu ON au.email = pu.email
        WHERE au.id != pu.id
        ORDER BY au.created_at
    LOOP
        RAISE NOTICE 'Processing email conflict: % (auth: %, public: %)', 
            conflict_record.email, conflict_record.auth_id, conflict_record.public_id;
        
        -- auth_idが既にpublic.usersに存在するかチェック
        IF EXISTS (SELECT 1 FROM users WHERE id = conflict_record.auth_id) THEN
            RAISE NOTICE 'Auth ID already exists in public.users, updating existing record';
            
            -- 既存レコードを更新
            UPDATE users 
            SET 
                name = COALESCE(conflict_record.old_name, name),
                user_id = COALESCE(conflict_record.old_user_id, user_id),
                phone = COALESCE(conflict_record.old_phone, phone),
                my_referral_code = COALESCE(conflict_record.old_referral_code, my_referral_code),
                referral_link = COALESCE(conflict_record.old_referral_link, referral_link),
                is_admin = COALESCE(conflict_record.old_is_admin, is_admin),
                referrer_id = COALESCE(conflict_record.old_referrer_id, referrer_id),
                usdt_address = COALESCE(conflict_record.old_usdt_address, usdt_address),
                wallet_type = COALESCE(conflict_record.old_wallet_type, wallet_type),
                password_changed = COALESCE(conflict_record.old_password_changed, password_changed),
                updated_at = NOW()
            WHERE id = conflict_record.auth_id;
            
        ELSE
            -- 新しいレコードを作成
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
                conflict_record.auth_id,
                COALESCE(conflict_record.old_name, split_part(conflict_record.email, '@', 1)),
                conflict_record.email,
                conflict_record.old_user_id,
                COALESCE(conflict_record.old_phone, ''),
                COALESCE(conflict_record.old_referral_code, 'REF' || UPPER(substring(md5(conflict_record.auth_id::text) from 1 for 8))),
                COALESCE(conflict_record.old_referral_link, 'https://shogun-trade.vercel.app/register?ref=' || COALESCE(conflict_record.old_referral_code, 'REF' || UPPER(substring(md5(conflict_record.auth_id::text) from 1 for 8)))),
                conflict_record.auth_created_at,
                NOW(),
                COALESCE(conflict_record.old_is_admin, CASE WHEN conflict_record.email = 'admin@shogun-trade.com' THEN true ELSE false END),
                conflict_record.old_referrer_id,
                conflict_record.old_usdt_address,
                conflict_record.old_wallet_type,
                COALESCE(conflict_record.old_password_changed, false)
            );
        END IF;
        
        -- 関連テーブルのuser_idを更新（1人1枚制限を考慮）
        
        -- user_nftsテーブル（重複チェック付き）
        UPDATE user_nfts 
        SET user_id = conflict_record.auth_id 
        WHERE user_id = conflict_record.public_id
        AND NOT EXISTS (
            SELECT 1 FROM user_nfts 
            WHERE user_id = conflict_record.auth_id 
            AND is_active = true
        );
        
        -- 重複がある場合は古いNFTを非アクティブ化
        UPDATE user_nfts 
        SET is_active = false 
        WHERE user_id = conflict_record.public_id
        AND EXISTS (
            SELECT 1 FROM user_nfts 
            WHERE user_id = conflict_record.auth_id 
            AND is_active = true
        );
        
        -- その他の関連テーブル
        UPDATE nft_purchase_applications 
        SET user_id = conflict_record.auth_id 
        WHERE user_id = conflict_record.public_id;
        
        UPDATE reward_applications 
        SET user_id = conflict_record.auth_id 
        WHERE user_id = conflict_record.public_id;
        
        UPDATE user_rank_history 
        SET user_id = conflict_record.auth_id 
        WHERE user_id = conflict_record.public_id;
        
        UPDATE tenka_bonus_distributions 
        SET user_id = conflict_record.auth_id 
        WHERE user_id = conflict_record.public_id;
        
        UPDATE daily_rewards 
        SET user_id = conflict_record.auth_id 
        WHERE user_id = conflict_record.public_id;
        
        -- 紹介関係の更新
        UPDATE users 
        SET referrer_id = conflict_record.auth_id 
        WHERE referrer_id = conflict_record.public_id;
        
        -- 古いpublic.usersレコードを削除
        DELETE FROM users WHERE id = conflict_record.public_id;
        
        RAISE NOTICE 'Consolidated user: % with preserved user_id: %', 
            conflict_record.email, conflict_record.old_user_id;
    END LOOP;
    
    -- Step 2: auth.usersに存在するがpublic.usersに存在しないユーザーを追加
    FOR conflict_record IN 
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
            conflict_record.id,
            split_part(conflict_record.email, '@', 1),
            conflict_record.email,
            new_user_id,
            '',
            'REF' || UPPER(substring(md5(conflict_record.id::text) from 1 for 8)),
            'https://shogun-trade.vercel.app/register?ref=' || 'REF' || UPPER(substring(md5(conflict_record.id::text) from 1 for 8)),
            conflict_record.created_at,
            NOW(),
            CASE WHEN conflict_record.email = 'admin@shogun-trade.com' THEN true ELSE false END,
            NULL,
            NULL,
            false
        );
        
        new_user_counter := new_user_counter + 1;
        
        RAISE NOTICE 'Added missing user: % with user_id: %', 
            conflict_record.email, new_user_id;
    END LOOP;
    
    RAISE NOTICE 'User consolidation completed successfully';
END $$;

-- 5. 外部キー制約を再作成
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

-- 6. 1人1枚制限のトリガーを再作成
DO $$
BEGIN
    CREATE TRIGGER trigger_one_nft_per_user
        BEFORE INSERT OR UPDATE ON user_nfts
        FOR EACH ROW
        EXECUTE FUNCTION check_one_nft_per_user();
    RAISE NOTICE '1人1枚制限トリガーを再作成しました';
END $$;

-- 7. 結果確認
SELECT 
    'After consolidation - auth.users' as table_name,
    COUNT(*) as count
FROM auth.users
UNION ALL
SELECT 
    'After consolidation - public.users' as table_name,
    COUNT(*) as count
FROM public.users
UNION ALL
SELECT 
    'Matched records' as table_name,
    COUNT(*) as count
FROM auth.users au
INNER JOIN public.users pu ON au.id = pu.id;

-- 8. 残りの不一致を確認
SELECT 
    'Remaining mismatches' as issue,
    'auth_only' as type,
    COUNT(*) as count
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL
UNION ALL
SELECT 
    'Remaining mismatches' as issue,
    'public_only' as type,
    COUNT(*) as count
FROM public.users pu
LEFT JOIN auth.users au ON pu.id = au.id
WHERE au.id IS NULL;

-- 9. admin001の確認
SELECT 
    'admin001 verification' as check_type,
    au.id as auth_id,
    pu.id as public_id,
    pu.user_id as user_id,
    pu.is_admin,
    CASE WHEN au.id = pu.id THEN 'MATCHED' ELSE 'MISMATCH' END as status
FROM auth.users au
FULL OUTER JOIN public.users pu ON au.email = pu.email
WHERE au.email = 'admin@shogun-trade.com' OR pu.email = 'admin@shogun-trade.com';

-- 10. 1人1枚制限の確認
SELECT 
    'NFT ownership check' as check_type,
    user_id,
    COUNT(*) as active_nft_count
FROM user_nfts 
WHERE is_active = true 
GROUP BY user_id 
HAVING COUNT(*) > 1
ORDER BY active_nft_count DESC;
