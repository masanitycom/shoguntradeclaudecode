-- 外部キー制約を考慮した復元

SELECT '=== 外部キー制約対応復元 ===' as section;

-- 1. 現在のusersテーブルに存在するIDのNFTのみ復元
SELECT 'usersテーブルに存在するNFTのみ復元中...' as action;
INSERT INTO user_nfts 
SELECT un.* 
FROM user_nfts_backup_20250730 un
WHERE EXISTS (
    SELECT 1 FROM users u WHERE u.id = un.user_id
);

-- 2. 復元結果確認
SELECT '復元完了確認:' as verification;
SELECT 
    COUNT(*) as restored_records
FROM user_nfts;

-- 3. 重要ユーザーの復元確認
SELECT '重要ユーザーの復元状況:' as important_users;
SELECT 
    u.name,
    u.user_id,
    CASE 
        WHEN un.id IS NOT NULL THEN 'NFT復元済み'
        ELSE 'NFTなし'
    END as nft_status,
    un.purchase_date,
    un.operation_start_date,
    un.current_investment
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE u.name IN (
    'サカイユカ2', 'サカイユカ3', 'ハギワラサナエ',
    'ササキジュンコ', 'ヤタガワタクミ', 'オオクボユイ'
)
ORDER BY u.name;

-- 4. 全体復元統計
SELECT '復元統計:' as stats;
SELECT 
    COUNT(*) as total_active_nfts,
    COUNT(DISTINCT user_id) as users_with_nfts,
    SUM(current_investment) as total_investment,
    AVG(current_investment) as avg_investment
FROM user_nfts
WHERE is_active = true;

SELECT '=== 制約対応復元完了 ===' as completed;