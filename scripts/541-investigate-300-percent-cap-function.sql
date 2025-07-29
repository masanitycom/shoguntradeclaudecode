-- check_300_percent_cap関数の詳細調査

-- 1. 現在の関数の定義を確認
SELECT 
    '🔍 check_300_percent_cap関数の定義' as info,
    proname as function_name,
    prosrc as function_source
FROM pg_proc 
WHERE proname = 'check_300_percent_cap';

-- 2. 関数が参照しているテーブル構造を確認
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

-- 3. daily_rewardsテーブルの構造を確認
SELECT 
    '📋 daily_rewards テーブル構造' as table_info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'daily_rewards' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. 挿入予定のデータを確認
SELECT 
    '🔍 挿入予定データ確認' as info,
    un.id as user_nft_id,
    un.user_id,
    un.nft_id,
    un.total_earned,
    un.purchase_price,
    un.purchase_price * 3 as max_earnings,
    CASE 
        WHEN un.total_earned >= un.purchase_price * 3 THEN '300%達成'
        ELSE '300%未達成'
    END as status
FROM user_nfts un
INNER JOIN nfts n ON un.nft_id = n.id
INNER JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
INNER JOIN users u ON un.user_id = u.id
WHERE un.is_active = true
AND un.purchase_date <= CURRENT_DATE
AND un.total_earned < un.purchase_price * 3
AND un.id IS NOT NULL
AND un.user_id IS NOT NULL
AND un.nft_id IS NOT NULL
AND un.purchase_price > 0
ORDER BY un.user_id, un.id
LIMIT 10;
