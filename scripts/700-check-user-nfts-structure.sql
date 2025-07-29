-- user_nftsテーブルの構造を確認

SELECT 
    'user_nfts テーブル構造確認' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'user_nfts'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 関連テーブルも確認
SELECT 
    'nfts テーブル構造確認' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'nfts'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- daily_rewards テーブル構造確認
SELECT 
    'daily_rewards テーブル構造確認' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'daily_rewards'
AND table_schema = 'public'
ORDER BY ordinal_position;
