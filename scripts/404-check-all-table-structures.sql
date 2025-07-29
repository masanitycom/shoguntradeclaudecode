-- 全テーブル構造確認

-- 1. users テーブル構造
SELECT 
    '👥 users テーブル構造' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. user_nfts テーブル構造
SELECT 
    '🎯 user_nfts テーブル構造' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_nfts' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. nfts テーブル構造
SELECT 
    '💎 nfts テーブル構造' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'nfts' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. daily_rewards テーブル構造
SELECT 
    '💰 daily_rewards テーブル構造' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 5. reward_applications テーブル構造（再確認）
SELECT 
    '📋 reward_applications テーブル構造' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'reward_applications' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 6. nft_purchase_applications テーブル構造
SELECT 
    '🛒 nft_purchase_applications テーブル構造' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'nft_purchase_applications' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 7. tasks テーブル構造
SELECT 
    '📝 tasks テーブル構造' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'tasks' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 8. auth.users テーブル構造
SELECT 
    '🔐 auth.users テーブル構造' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
  AND table_schema = 'auth'
ORDER BY ordinal_position;

-- 9. 全テーブル一覧確認
SELECT 
    '📊 全テーブル一覧' as info,
    table_schema,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema IN ('public', 'auth')
  AND table_type = 'BASE TABLE'
ORDER BY table_schema, table_name;

-- 10. 各テーブルのサンプルデータ確認
SELECT '👥 users サンプル' as info, user_id, name, email, created_at FROM users LIMIT 3;
SELECT '🎯 user_nfts サンプル' as info, id, user_id, nft_id, current_investment, total_earned FROM user_nfts LIMIT 3;
SELECT '💎 nfts サンプル' as info, id, name, price, daily_rate_limit FROM nfts LIMIT 3;
SELECT '💰 daily_rewards サンプル' as info, id, user_nft_id, reward_amount, reward_date, is_claimed FROM daily_rewards LIMIT 3;
SELECT '📋 reward_applications サンプル' as info, id, user_id, total_reward_amount, status, applied_at FROM reward_applications LIMIT 3;
SELECT '🛒 nft_purchase_applications サンプル' as info, id, user_id, nft_id, status, created_at FROM nft_purchase_applications LIMIT 3;
