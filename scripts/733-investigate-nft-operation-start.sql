-- 🚨 NFT運用開始日の緊急調査

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

-- 2. 実際のuser_nftsデータ確認
SELECT 
    '=== 実際のNFTデータ ===' as section,
    un.id,
    un.user_id,
    un.nft_id,
    un.current_investment,
    un.total_earned,
    un.is_active,
    un.created_at,
    un.updated_at,
    -- purchase_dateカラムがあるかチェック
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'user_nfts' 
            AND column_name = 'purchase_date'
        ) THEN 'purchase_dateカラム存在'
        ELSE 'purchase_dateカラム不存在'
    END as purchase_date_status,
    n.name as nft_name,
    n.price as nft_price
FROM user_nfts un
JOIN nfts n ON un.nft_id = n.id
WHERE un.is_active = true
ORDER BY un.created_at DESC;

-- 3. NFT購入申請テーブルの確認
SELECT 
    '=== NFT購入申請状況 ===' as section,
    npa.id,
    npa.user_id,
    npa.nft_id,
    npa.status,
    npa.created_at as application_date,
    npa.approved_at,
    n.name as nft_name,
    n.price
FROM nft_purchase_applications npa
JOIN nfts n ON npa.nft_id = n.id
ORDER BY npa.created_at DESC;

-- 4. ユーザー別NFT運用状況の詳細
SELECT 
    '=== ユーザー別NFT運用詳細 ===' as section,
    u.name as user_name,
    u.email,
    n.name as nft_name,
    n.price as nft_price,
    un.current_investment,
    un.total_earned,
    un.max_earning,
    un.is_active,
    un.created_at as nft_created_at,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'user_nfts' 
            AND column_name = 'purchase_date'
        ) THEN '購入日カラム存在'
        ELSE '購入日カラム不存在'
    END as purchase_date_column_status,
    CASE 
        WHEN un.created_at IS NULL THEN '🚨 作成日未設定'
        WHEN un.created_at::DATE > CURRENT_DATE THEN '🚨 未来日付'
        WHEN un.created_at::DATE = CURRENT_DATE THEN '✅ 今日作成'
        ELSE FORMAT('✅ %s日前作成', CURRENT_DATE - un.created_at::DATE)
    END as operation_status
FROM users u
JOIN user_nfts un ON u.id = un.user_id
JOIN nfts n ON un.nft_id = n.id
WHERE u.is_admin = false
AND un.is_active = true
ORDER BY u.name, un.created_at DESC;

-- 5. 運用開始日の問題診断
SELECT 
    '=== 運用開始日問題診断 ===' as section,
    COUNT(*) as total_active_nfts,
    COUNT(CASE WHEN un.created_at IS NULL THEN 1 END) as nfts_without_created_at,
    COUNT(CASE WHEN un.created_at::DATE > CURRENT_DATE THEN 1 END) as nfts_with_future_date,
    COUNT(CASE WHEN un.current_investment IS NULL OR un.current_investment = 0 THEN 1 END) as nfts_without_investment,
    COUNT(CASE WHEN un.total_earned IS NULL THEN 1 END) as nfts_without_earned_tracking,
    MIN(un.created_at) as earliest_nft_date,
    MAX(un.created_at) as latest_nft_date
FROM user_nfts un
WHERE un.is_active = true;

-- 6. 日利報酬テーブルの状況
SELECT 
    '=== 日利報酬の状況 ===' as section,
    COUNT(*) as total_rewards,
    COUNT(CASE WHEN is_claimed = false THEN 1 END) as pending_rewards,
    COALESCE(SUM(reward_amount), 0) as total_reward_amount,
    COALESCE(MIN(reward_date)::TEXT, 'なし') as earliest_reward,
    COALESCE(MAX(reward_date)::TEXT, 'なし') as latest_reward
FROM daily_rewards;

-- 7. 週利設定の状況
SELECT 
    '=== 週利設定状況 ===' as section,
    gwr.group_name,
    gwr.week_start_date,
    gwr.monday_rate,
    gwr.tuesday_rate,
    gwr.wednesday_rate,
    gwr.thursday_rate,
    gwr.friday_rate,
    (gwr.monday_rate + gwr.tuesday_rate + gwr.wednesday_rate + gwr.thursday_rate + gwr.friday_rate) as total_weekly_rate
FROM group_weekly_rates gwr
ORDER BY gwr.week_start_date DESC;

SELECT '🚨 NFT運用開始日調査完了' as status;
