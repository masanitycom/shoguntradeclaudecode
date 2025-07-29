-- 【安全】既存テーブル構造確認SQL（読み取りのみ）

-- 1. 既存ユーザー数確認
SELECT 'ユーザー数確認' as check_type, COUNT(*) as count FROM users;

-- 2. 管理者数確認
SELECT '管理者数確認' as check_type, COUNT(*) as count FROM users WHERE is_admin = true;

-- 3. 既存NFT一覧確認
SELECT 'NFT一覧' as check_type, name, price, is_special FROM nfts ORDER BY price;

-- 4. アクティブなuser_nfts数確認
SELECT 'アクティブNFT数' as check_type, COUNT(*) as count FROM user_nfts WHERE is_active = true;

-- 5. NFTを持たないユーザー数確認
SELECT 'NFT未保有ユーザー数' as check_type, COUNT(*) as count 
FROM users u 
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true 
WHERE un.id IS NULL AND u.is_admin = false;

-- 6. 既存テーブルの存在確認
SELECT 
    'テーブル存在確認' as check_type,
    table_name,
    CASE WHEN table_name IS NOT NULL THEN '存在' ELSE '未存在' END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('tasks', 'nft_purchase_applications', 'reward_applications', 'payment_addresses', 'holidays_jp', 'weekly_profits')
ORDER BY table_name;

-- 7. user_nftsテーブルの構造確認
SELECT 
    'user_nftsカラム確認' as check_type,
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_nfts' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 8. 1人で複数NFTを持つユーザーがいるかチェック（重要）
SELECT 
    '複数NFT保有チェック' as check_type,
    user_id,
    COUNT(*) as nft_count
FROM user_nfts 
WHERE is_active = true 
GROUP BY user_id 
HAVING COUNT(*) > 1;

-- 完了メッセージ
SELECT '既存データ確認完了 - データは一切変更されていません' as result;
