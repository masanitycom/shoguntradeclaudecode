-- ユーザー登録日とNFT取得の時系列確認

-- 1. ユーザー登録日とNFT取得日の時系列
SELECT 
    '📈 ユーザー登録とNFT取得の時系列' as info,
    u.user_id,
    u.name as ユーザー名,
    u.created_at as ユーザー登録日時,
    u.created_at::date as ユーザー登録日,
    un.created_at as NFT取得日時,
    un.created_at::date as NFT取得日,
    n.name as NFT名,
    (un.created_at::date - u.created_at::date) as 登録からNFT取得までの日数,
    CASE 
        WHEN u.created_at::date >= '2025-02-15' THEN '❌ 2/10週後に登録'
        WHEN un.created_at::date >= '2025-02-15' THEN '❌ 2/10週後にNFT取得'
        WHEN un.created_at::date <= '2025-02-10' THEN '✅ 2/10週開始前にNFT取得済み'
        ELSE '⚠️ 2/10週中にNFT取得'
    END as 対象判定
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
LEFT JOIN nfts n ON un.nft_id = n.id
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1')
ORDER BY u.user_id;

-- 2. 2025年2月の重要な日付との比較
SELECT 
    '📅 重要日付との比較' as info,
    u.user_id,
    u.name as ユーザー名,
    u.created_at::date as ユーザー登録日,
    un.created_at::date as NFT取得日,
    '2025-02-10'::date as 週利開始日,
    '2025-02-14'::date as 週利終了日,
    CASE 
        WHEN un.created_at::date IS NULL THEN '❌ NFT未取得'
        WHEN un.created_at::date > '2025-02-14' THEN '❌ 2/10週終了後にNFT取得'
        WHEN un.created_at::date > '2025-02-10' THEN 
            '⚠️ 2/10週中にNFT取得（' || 
            CASE un.created_at::date
                WHEN '2025-02-11' THEN '2/11(火)から対象'
                WHEN '2025-02-12' THEN '2/12(水)から対象'
                WHEN '2025-02-13' THEN '2/13(木)から対象'
                WHEN '2025-02-14' THEN '2/14(金)から対象'
            END || '）'
        ELSE '✅ 2/10週全期間対象'
    END as 対象期間判定
FROM users u
LEFT JOIN user_nfts un ON u.id = un.user_id AND un.is_active = true
WHERE u.user_id IN ('OHTAKIYO', 'imaima3137', 'pbcshop1', 'noriko1')
ORDER BY u.user_id;

-- 3. システム全体の2025-02-10週対象ユーザー数確認
SELECT 
    '📊 システム全体の2/10週対象状況' as info,
    COUNT(*) as 総NFT数,
    COUNT(CASE WHEN un.created_at::date <= '2025-02-10' THEN 1 END) as 全期間対象NFT数,
    COUNT(CASE WHEN un.created_at::date BETWEEN '2025-02-11' AND '2025-02-14' THEN 1 END) as 部分期間対象NFT数,
    COUNT(CASE WHEN un.created_at::date > '2025-02-14' THEN 1 END) as 対象外NFT数,
    COUNT(CASE WHEN un.created_at::date <= '2025-02-14' THEN 1 END) as 何らかの対象NFT数
FROM user_nfts un
WHERE un.is_active = true;
