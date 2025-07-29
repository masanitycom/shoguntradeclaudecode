-- 重複キー問題の詳細調査

-- 1. 同じメールアドレスを持つユーザーの詳細確認
SELECT 
    'Email duplicates investigation' as check_type,
    au.id as auth_id,
    au.email as auth_email,
    au.created_at as auth_created,
    pu.id as public_id,
    pu.email as public_email,
    pu.user_id as public_user_id,
    pu.created_at as public_created,
    CASE 
        WHEN au.id = pu.id THEN 'ID_MATCH'
        WHEN au.email = pu.email AND au.id != pu.id THEN 'EMAIL_MATCH_ID_DIFF'
        ELSE 'OTHER'
    END as match_type
FROM auth.users au
FULL OUTER JOIN public.users pu ON au.email = pu.email
WHERE au.email = pu.email AND au.id != pu.id
ORDER BY au.email, au.created_at;

-- 2. 問題のあるIDの詳細確認
SELECT 
    'Problematic ID analysis' as check_type,
    id,
    email,
    'auth.users' as source_table
FROM auth.users 
WHERE id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
UNION ALL
SELECT 
    'Problematic ID analysis' as check_type,
    id,
    email,
    'public.users' as source_table
FROM public.users 
WHERE id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c';

-- 3. 同じIDを持つユーザーの確認
SELECT 
    'Same ID different tables' as check_type,
    au.id,
    au.email as auth_email,
    pu.email as public_email,
    pu.user_id,
    au.created_at as auth_created,
    pu.created_at as public_created
FROM auth.users au
INNER JOIN public.users pu ON au.id = pu.id
WHERE au.email != pu.email
ORDER BY au.created_at;

-- 4. メールアドレス重複の統計
SELECT 
    'Email duplication stats' as check_type,
    email,
    COUNT(*) as count_in_auth
FROM auth.users 
GROUP BY email 
HAVING COUNT(*) > 1
UNION ALL
SELECT 
    'Email duplication stats' as check_type,
    email,
    COUNT(*) as count_in_public
FROM public.users 
GROUP BY email 
HAVING COUNT(*) > 1;

-- 5. 関連データの確認
SELECT 
    'Related data check' as check_type,
    'user_nfts' as table_name,
    user_id,
    COUNT(*) as record_count
FROM user_nfts 
WHERE user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
GROUP BY user_id
UNION ALL
SELECT 
    'Related data check' as check_type,
    'nft_purchase_applications' as table_name,
    user_id,
    COUNT(*) as record_count
FROM nft_purchase_applications 
WHERE user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
GROUP BY user_id
UNION ALL
SELECT 
    'Related data check' as check_type,
    'reward_applications' as table_name,
    user_id,
    COUNT(*) as record_count
FROM reward_applications 
WHERE user_id = '3aa5c0de-8d2c-40b0-bdb5-3687d026ca5c'
GROUP BY user_id;
