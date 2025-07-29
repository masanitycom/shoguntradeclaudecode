-- 安全なユーザー認証同期スクリプト（制約削除・再作成版）

-- 1. まず現在の状況を確認
SELECT 
    'Before sync - auth.users' as table_name,
    COUNT(*) as count
FROM auth.users
UNION ALL
SELECT 
    'Before sync - public.users' as table_name,
    COUNT(*) as count
FROM public.users;

-- 2. 外部キー制約を一時的に削除
ALTER TABLE user_nfts DROP CONSTRAINT IF EXISTS user_nfts_user_id_fkey;
ALTER TABLE daily_rewards DROP CONSTRAINT IF EXISTS daily_rewards_user_id_fkey;
ALTER TABLE reward_applications DROP CONSTRAINT IF EXISTS reward_applications_user_id_fkey;
ALTER TABLE nft_purchase_applications DROP CONSTRAINT IF EXISTS nft_purchase_applications_user_id_fkey;
ALTER TABLE user_rank_history DROP CONSTRAINT IF EXISTS user_rank_history_user_id_fkey;
ALTER TABLE tenka_bonus_distributions DROP CONSTRAINT IF EXISTS tenka_bonus_distributions_user_id_fkey;
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_referrer_id_fkey;

-- 3. 安全にユーザーIDを統合
DO $$
DECLARE
    conflict_record RECORD;
    new_user_counter INTEGER := 1;
    new_user_id TEXT;
    max_user_num INTEGER;
BEGIN
    RAISE NOTICE 'Starting safe user ID consolidation...';
    
    -- 既存の最大USER番号を取得
    SELECT COALESCE(MAX(CAST(SUBSTRING(user_id FROM 5) AS INTEGER)), 0) + 1
    INTO max_user_num
    FROM users 
    WHERE user_id ~ '^USER[0-9]+$';
    
    new_user_counter := GREATEST(max_user_num, 1);
    
    -- メールアドレス重複の解決
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
            pu.referrer_id as old_referrer_id
        FROM auth.users au
        INNER JOIN public.users pu ON au.email = pu.email
        WHERE au.id != pu.id
        ORDER BY au.created_at
    LOOP
        RAISE NOTICE 'Processing email conflict: % (auth: %, public: %)', 
            conflict_record.email, conflict_record.auth_id, conflict_record.public_id;
        
        -- 関連テーブルのレコードをauth_idに統合
        UPDATE user_nfts 
        SET user_id = conflict_record.auth_id 
        WHERE user_id = conflict_record.public_id;
        
        UPDATE daily_rewards 
        SET user_id = conflict_record.auth_id 
        WHERE user_id = conflict_record.public_id;
        
        UPDATE reward_applications 
        SET user_id = conflict_record.auth_id 
        WHERE user_id = conflict_record.public_id;
        
        UPDATE nft_purchase_applications 
        SET user_id = conflict_record.auth_id 
        WHERE user_id = conflict_record.public_id;
        
        UPDATE user_rank_history 
        SET user_id = conflict_record.auth_id 
        WHERE user_id = conflict_record.public_id;
        
        UPDATE tenka_bonus_distributions 
        SET user_id = conflict_record.auth_id 
        WHERE user_id = conflict_record.public_id;
        
        -- 紹介関係の更新
        UPDATE users 
        SET referrer_id = conflict_record.auth_id 
        WHERE referrer_id = conflict_record.public_id;
        
        -- 古いpublic.usersレコードを削除
        DELETE FROM users WHERE id = conflict_record.public_id;
        
        -- 新しいpublic.usersレコードを作成（auth.usersのIDで、既存データを保持）
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
            current_rank
        ) VALUES (
            conflict_record.auth_id,
            COALESCE(conflict_record.old_name, split_part(conflict_record.email, '@', 1)),
            conflict_record.email,
            conflict_record.old_user_id, -- 既存のuser_idを保持
            COALESCE(conflict_record.old_phone, ''),
            COALESCE(conflict_record.old_referral_code, 'REF' || UPPER(substring(md5(conflict_record.auth_id::text) from 1 for 8))),
            COALESCE(conflict_record.old_referral_link, 'https://shogun-trade.vercel.app/register?ref=' || COALESCE(conflict_record.old_referral_code, 'REF' || UPPER(substring(md5(conflict_record.auth_id::text) from 1 for 8)))),
            conflict_record.auth_created_at,
            NOW(),
            COALESCE(conflict_record.old_is_admin, CASE WHEN conflict_record.email = 'admin@shogun-trade.com' THEN true ELSE false END),
            conflict_record.old_referrer_id,
            0
        );
        
        RAISE NOTICE 'Consolidated user: % with preserved user_id: %', 
            conflict_record.email, conflict_record.old_user_id;
    END LOOP;
    
    -- auth.usersに存在するがpublic.usersに存在しないユーザーを追加
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
            current_rank
        ) VALUES (
            conflict_record.id,
            COALESCE(split_part(conflict_record.email, '@', 1), 'User' || new_user_counter),
            conflict_record.email,
            new_user_id,
            '',
            'REF' || UPPER(substring(md5(conflict_record.id::text) from 1 for 8)),
            'https://shogun-trade.vercel.app/register?ref=' || 'REF' || UPPER(substring(md5(conflict_record.id::text) from 1 for 8)),
            conflict_record.created_at,
            NOW(),
            CASE WHEN conflict_record.email = 'admin@shogun-trade.com' THEN true ELSE false END,
            0
        );
        
        new_user_counter := new_user_counter + 1;
        
        RAISE NOTICE 'Added missing user: % with user_id: %', 
            conflict_record.email, new_user_id;
    END LOOP;
    
    RAISE NOTICE 'User consolidation completed successfully';
END $$;

-- 4. 外部キー制約を再作成
ALTER TABLE user_nfts 
ADD CONSTRAINT user_nfts_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE daily_rewards 
ADD CONSTRAINT daily_rewards_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE reward_applications 
ADD CONSTRAINT reward_applications_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE nft_purchase_applications 
ADD CONSTRAINT nft_purchase_applications_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE user_rank_history 
ADD CONSTRAINT user_rank_history_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE tenka_bonus_distributions 
ADD CONSTRAINT tenka_bonus_distributions_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE users 
ADD CONSTRAINT users_referrer_id_fkey 
FOREIGN KEY (referrer_id) REFERENCES users(id) ON DELETE SET NULL;

-- 5. 結果確認
SELECT 
    'After sync - auth.users' as table_name,
    COUNT(*) as count
FROM auth.users
UNION ALL
SELECT 
    'After sync - public.users' as table_name,
    COUNT(*) as count
FROM public.users
UNION ALL
SELECT 
    'Matched records' as table_name,
    COUNT(*) as count
FROM auth.users au
INNER JOIN public.users pu ON au.id = pu.id;

-- 6. 残りの不一致を確認
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

-- 7. admin001の確認
SELECT 
    'admin001 verification' as check_type,
    au.id as auth_id,
    pu.id as public_id,
    pu.user_id as user_id,
    CASE WHEN au.id = pu.id THEN 'MATCHED' ELSE 'MISMATCH' END as status
FROM auth.users au
FULL OUTER JOIN public.users pu ON au.email = pu.email
WHERE au.email = 'admin@shogun-trade.com' OR pu.email = 'admin@shogun-trade.com';

-- 8. 最終的なデータ整合性チェック
SELECT 
    'Data integrity check' as check_type,
    'user_nfts orphans' as detail,
    COUNT(*) as count
FROM user_nfts un
LEFT JOIN users u ON un.user_id = u.id
WHERE u.id IS NULL
UNION ALL
SELECT 
    'Data integrity check' as check_type,
    'daily_rewards orphans' as detail,
    COUNT(*) as count
FROM daily_rewards dr
LEFT JOIN users u ON dr.user_id = u.id
WHERE u.id IS NULL
UNION ALL
SELECT 
    'Data integrity check' as check_type,
    'reward_applications orphans' as detail,
    COUNT(*) as count
FROM reward_applications ra
LEFT JOIN users u ON ra.user_id = u.id
WHERE u.id IS NULL;
