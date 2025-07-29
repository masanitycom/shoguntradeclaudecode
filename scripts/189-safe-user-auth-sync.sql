-- 安全なユーザー認証同期スクリプト

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

-- 2. 外部キー制約を一時的に無効化
ALTER TABLE user_nfts DISABLE TRIGGER ALL;
ALTER TABLE daily_rewards DISABLE TRIGGER ALL;
ALTER TABLE reward_applications DISABLE TRIGGER ALL;
ALTER TABLE nft_purchase_applications DISABLE TRIGGER ALL;
ALTER TABLE user_rank_history DISABLE TRIGGER ALL;
ALTER TABLE tenka_bonus_distributions DISABLE TRIGGER ALL;

-- 3. 安全にユーザーIDを統合
DO $$
DECLARE
    conflict_record RECORD;
    new_user_counter INTEGER := 1;
    new_user_id TEXT;
BEGIN
    RAISE NOTICE 'Starting safe user ID consolidation...';
    
    -- メールアドレス重複の解決
    FOR conflict_record IN 
        SELECT 
            au.id as auth_id,
            au.email,
            au.created_at as auth_created_at,
            pu.id as public_id,
            pu.created_at as public_created_at
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
        
        -- 新しいpublic.usersレコードを作成（auth.usersのIDで）
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
            is_admin
        ) VALUES (
            conflict_record.auth_id,
            COALESCE(split_part(conflict_record.email, '@', 1), 'User' || new_user_counter),
            conflict_record.email,
            new_user_id,
            '',
            'REF' || UPPER(substring(md5(conflict_record.auth_id::text) from 1 for 8)),
            'https://shogun-trade.vercel.app/register?ref=' || 'REF' || UPPER(substring(md5(conflict_record.auth_id::text) from 1 for 8)),
            conflict_record.auth_created_at,
            NOW(),
            CASE WHEN conflict_record.email = 'admin@shogun-trade.com' THEN true ELSE false END
        );
        
        new_user_counter := new_user_counter + 1;
        
        RAISE NOTICE 'Consolidated user: % with new user_id: %', 
            conflict_record.email, new_user_id;
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
            is_admin
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
            CASE WHEN conflict_record.email = 'admin@shogun-trade.com' THEN true ELSE false END
        );
        
        new_user_counter := new_user_counter + 1;
        
        RAISE NOTICE 'Added missing user: % with user_id: %', 
            conflict_record.email, new_user_id;
    END LOOP;
    
    RAISE NOTICE 'User consolidation completed successfully';
END $$;

-- 4. 外部キー制約を再有効化
ALTER TABLE user_nfts ENABLE TRIGGER ALL;
ALTER TABLE daily_rewards ENABLE TRIGGER ALL;
ALTER TABLE reward_applications ENABLE TRIGGER ALL;
ALTER TABLE nft_purchase_applications ENABLE TRIGGER ALL;
ALTER TABLE user_rank_history ENABLE TRIGGER ALL;
ALTER TABLE tenka_bonus_distributions ENABLE TRIGGER ALL;

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
    CASE WHEN au.id = pu.id THEN 'MATCHED' ELSE 'MISMATCH' END as status
FROM auth.users au
FULL OUTER JOIN public.users pu ON au.email = pu.email
WHERE au.email = 'admin@shogun-trade.com' OR pu.email = 'admin@shogun-trade.com';
