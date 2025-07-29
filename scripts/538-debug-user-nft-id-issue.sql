-- user_nft_idがNULLになる原因を調査

-- 1. user_nftsテーブルの構造確認
SELECT 
    '📋 user_nfts テーブル構造' as table_info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_nfts' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. アクティブなuser_nftsの確認
SELECT 
    '📊 アクティブuser_nfts確認' as info,
    COUNT(*) as total_active_nfts,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT nft_id) as unique_nfts,
    MIN(purchase_date) as earliest_purchase,
    MAX(purchase_date) as latest_purchase
FROM user_nfts 
WHERE is_active = true;

-- 3. 具体的なuser_nftsデータサンプル
SELECT 
    '🔍 user_nfts サンプルデータ' as info,
    id as user_nft_id,
    user_id,
    nft_id,
    purchase_price,
    total_earned,
    is_active,
    purchase_date
FROM user_nfts 
WHERE is_active = true
ORDER BY purchase_date DESC
LIMIT 10;

-- 4. NULLのuser_nft_idがあるかチェック
SELECT 
    '⚠️ NULL user_nft_id チェック' as info,
    COUNT(*) as null_user_nft_ids,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as null_user_ids,
    COUNT(CASE WHEN nft_id IS NULL THEN 1 END) as null_nft_ids
FROM user_nfts;

-- 5. daily_rewardsでNULLのuser_nft_idがあるかチェック
SELECT 
    '⚠️ daily_rewards NULL チェック' as info,
    COUNT(*) as total_records,
    COUNT(CASE WHEN user_nft_id IS NULL THEN 1 END) as null_user_nft_ids,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as null_user_ids,
    COUNT(CASE WHEN nft_id IS NULL THEN 1 END) as null_nft_ids
FROM daily_rewards;

-- 6. 制約とトリガーの詳細確認
SELECT 
    '🔧 daily_rewards 制約詳細' as constraint_info,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
LEFT JOIN information_schema.constraint_column_usage ccu 
    ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_name = 'daily_rewards' 
    AND tc.table_schema = 'public';

-- 7. トリガー関数の詳細確認
SELECT 
    '🔧 トリガー関数確認' as trigger_info,
    proname as function_name,
    prosrc as function_source
FROM pg_proc 
WHERE proname LIKE '%300%' 
   OR proname LIKE '%cap%' 
   OR proname LIKE '%check%';

-- 8. 実際のトリガー確認
SELECT 
    '🔧 実際のトリガー確認' as trigger_info,
    t.tgname as trigger_name,
    c.relname as table_name,
    p.proname as function_name,
    t.tgenabled as enabled
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE c.relname = 'daily_rewards';
