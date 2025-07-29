-- 🔍 ユーザーNFTの運用開始日詳細調査
-- 週利設定期間と運用開始日の整合性チェック

-- 1. user_nftsテーブルの構造確認
SELECT 
    '=== user_nfts テーブル構造 ===' as section,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'user_nfts'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. 各ユーザーのNFT運用開始日を詳細表示
SELECT 
    '=== ユーザーNFT運用開始日詳細 ===' as section,
    u.name as user_name,
    u.email,
    n.name as nft_name,
    n.price as nft_price,
    un.current_investment,
    un.is_active,
    un.created_at as nft_created_date,
    un.created_at::DATE as operation_start_date,
    CURRENT_DATE as today,
    CURRENT_DATE - un.created_at::DATE as days_since_start,
    CASE 
        WHEN un.created_at IS NULL THEN '🚨 運用開始日未設定'
        WHEN un.created_at::DATE > CURRENT_DATE THEN FORMAT('🚨 未来日付エラー (%s)', un.created_at::DATE)
        WHEN un.created_at::DATE >= '2025-02-10' THEN FORMAT('✅ 週利期間内開始 (%s)', un.created_at::DATE)
        WHEN un.created_at::DATE < '2025-02-10' THEN FORMAT('⚠️ 週利設定前開始 (%s)', un.created_at::DATE)
        ELSE '❓ 不明'
    END as start_date_status,
    CASE 
        WHEN un.current_investment IS NULL OR un.current_investment = 0 THEN '🚨 投資額未設定'
        WHEN un.current_investment != n.price THEN FORMAT('⚠️ 投資額不一致 (設定:%s, NFT価格:%s)', un.current_investment, n.price)
        ELSE '✅ 投資額正常'
    END as investment_status
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
WHERE u.is_admin = false
ORDER BY u.name, un.created_at;

-- 3. purchase_dateカラムが存在する場合の確認
SELECT 
    '=== purchase_date確認 ===' as section,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'user_nfts' 
            AND column_name = 'purchase_date'
        ) THEN 'purchase_dateカラム存在'
        ELSE 'purchase_dateカラム不存在'
    END as purchase_date_column_status;

-- 4. 運用開始日と週利設定期間の整合性チェック
SELECT 
    '=== 運用開始日と週利期間の整合性 ===' as section,
    u.name as user_name,
    n.name as nft_name,
    un.created_at::DATE as operation_start_date,
    '2025-02-10' as earliest_weekly_rate_date,
    '2025-03-24' as latest_weekly_rate_date,
    CASE 
        WHEN un.created_at IS NULL THEN '🚨 運用開始日未設定 → 報酬発生しない'
        WHEN un.created_at::DATE > CURRENT_DATE THEN '🚨 未来日付 → 報酬発生しない'
        WHEN un.created_at::DATE > '2025-03-24' THEN '🚨 週利設定期間後の開始 → 報酬発生しない'
        WHEN un.created_at::DATE >= '2025-02-10' THEN '✅ 週利期間内開始 → 報酬発生可能'
        WHEN un.created_at::DATE < '2025-02-10' THEN '✅ 週利設定前開始 → 報酬発生可能'
        ELSE '❓ 判定不能'
    END as reward_eligibility,
    CASE 
        WHEN un.is_active = false THEN '❌ NFT非アクティブ'
        WHEN un.current_investment IS NULL OR un.current_investment = 0 THEN '❌ 投資額未設定'
        ELSE '✅ その他条件OK'
    END as other_conditions
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
WHERE u.is_admin = false
ORDER BY un.created_at::DATE DESC;

-- 5. 問題のあるNFTの特定
SELECT 
    '=== 問題のあるNFT特定 ===' as section,
    COUNT(*) as total_user_nfts,
    COUNT(CASE WHEN un.created_at IS NULL THEN 1 END) as nfts_without_start_date,
    COUNT(CASE WHEN un.created_at::DATE > CURRENT_DATE THEN 1 END) as nfts_with_future_date,
    COUNT(CASE WHEN un.created_at::DATE > '2025-03-24' THEN 1 END) as nfts_started_after_weekly_rates,
    COUNT(CASE WHEN un.current_investment IS NULL OR un.current_investment = 0 THEN 1 END) as nfts_without_investment,
    COUNT(CASE WHEN un.is_active = false THEN 1 END) as inactive_nfts,
    COUNT(CASE 
        WHEN un.created_at IS NOT NULL 
        AND un.created_at::DATE <= CURRENT_DATE 
        AND un.is_active = true 
        AND un.current_investment > 0 
        THEN 1 
    END) as eligible_for_rewards
FROM user_nfts un
JOIN users u ON un.user_id = u.id
WHERE u.is_admin = false;

-- 6. 具体的な問題NFTリスト
SELECT 
    '=== 具体的な問題NFTリスト ===' as section,
    u.name as user_name,
    n.name as nft_name,
    un.created_at::DATE as operation_start_date,
    CASE 
        WHEN un.created_at IS NULL THEN '運用開始日未設定'
        WHEN un.created_at::DATE > CURRENT_DATE THEN FORMAT('未来日付: %s', un.created_at::DATE)
        WHEN un.created_at::DATE > '2025-03-24' THEN FORMAT('週利設定期間後: %s', un.created_at::DATE)
        WHEN un.current_investment IS NULL OR un.current_investment = 0 THEN '投資額未設定'
        WHEN un.is_active = false THEN 'NFT非アクティブ'
        ELSE '問題なし'
    END as problem_type
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
WHERE u.is_admin = false
AND (
    un.created_at IS NULL 
    OR un.created_at::DATE > CURRENT_DATE
    OR un.created_at::DATE > '2025-03-24'
    OR un.current_investment IS NULL 
    OR un.current_investment = 0
    OR un.is_active = false
)
ORDER BY u.name, un.created_at;

SELECT '🔍 ユーザーNFT運用開始日調査完了 - 週利期間との整合性チェック済み' as status;
