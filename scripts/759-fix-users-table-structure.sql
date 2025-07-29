-- usersテーブルに不足しているカラムを追加

-- 1. usersテーブルに必要なカラムを追加
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS active_nft_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_investment NUMERIC DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_earned NUMERIC DEFAULT 0;

-- 2. 既存データの更新
UPDATE users 
SET 
    total_investment = COALESCE(user_stats.total_investment, 0),
    total_earned = COALESCE(user_stats.total_earned, 0),
    active_nft_count = COALESCE(user_stats.active_nft_count, 0)
FROM (
    SELECT 
        un.user_id,
        SUM(un.purchase_price) as total_investment,
        SUM(un.total_earned) as total_earned,
        COUNT(un.id) as active_nft_count
    FROM user_nfts un
    WHERE un.is_active = true
    GROUP BY un.user_id
) user_stats
WHERE users.id = user_stats.user_id;

-- 3. テーブル構造の確認
SELECT 
    '=== 修正後 users テーブル構造 ===' as section,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT '✅ usersテーブル構造修正完了' as status;
