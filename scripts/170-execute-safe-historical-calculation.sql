-- 安全な過去分計算の実行と詳細確認

-- 1. 過去分計算を実行（週2-19）
SELECT * FROM calculate_nft_historical_rewards_safe(2, 19);

-- 2. 計算完了ステータス
SELECT 'Calculation completed. Verifying results...' as status;

-- 3. NFT別の計算結果サマリー
SELECT 
    n.name as nft_name,
    COUNT(dr.id) as total_rewards,
    SUM(dr.reward_amount) as total_amount,
    AVG(dr.reward_amount) as avg_daily_reward,
    MIN(dr.reward_date) as first_reward_date,
    MAX(dr.reward_date) as last_reward_date
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
WHERE dr.reward_date >= '2025-01-13'  -- 週2開始日
AND dr.reward_date <= '2025-05-16'    -- 週19終了日
GROUP BY n.id, n.name
ORDER BY n.name;

-- 4. 週別の報酬分布確認
SELECT 
    EXTRACT(WEEK FROM dr.reward_date) as week_number,
    COUNT(dr.id) as total_rewards,
    SUM(dr.reward_amount) as total_amount,
    COUNT(DISTINCT n.id) as unique_nfts,
    COUNT(DISTINCT dr.user_nft_id) as unique_user_nfts
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
WHERE dr.reward_date >= '2025-01-13'
AND dr.reward_date <= '2025-05-16'
GROUP BY EXTRACT(WEEK FROM dr.reward_date)
ORDER BY week_number;

-- 5. ユーザー別の過去分報酬上位10名（usernameカラムの存在確認）
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'username'
    ) THEN
        -- usernameカラムがある場合
        EXECUTE '
        SELECT 
            u.username,
            COUNT(dr.id) as total_rewards,
            SUM(dr.reward_amount) as total_amount,
            COUNT(DISTINCT un.nft_id) as nft_types
        FROM daily_rewards dr
        JOIN user_nfts un ON dr.user_nft_id = un.id
        JOIN users u ON un.user_id = u.id
        WHERE dr.reward_date >= ''2025-01-13''
        AND dr.reward_date <= ''2025-05-16''
        GROUP BY u.id, u.username
        ORDER BY total_amount DESC
        LIMIT 10';
    ELSE
        -- usernameカラムがない場合はemailを使用
        EXECUTE '
        SELECT 
            u.email,
            COUNT(dr.id) as total_rewards,
            SUM(dr.reward_amount) as total_amount,
            COUNT(DISTINCT un.nft_id) as nft_types
        FROM daily_rewards dr
        JOIN user_nfts un ON dr.user_nft_id = un.id
        JOIN users u ON un.user_id = u.id
        WHERE dr.reward_date >= ''2025-01-13''
        AND dr.reward_date <= ''2025-05-16''
        GROUP BY u.id, u.email
        ORDER BY total_amount DESC
        LIMIT 10';
    END IF;
END $$;

-- 6. SHOGUN NFT 100000の特別確認（週2-9は0%のはず）
SELECT 
    dr.reward_date,
    dr.daily_rate,
    dr.reward_amount,
    EXTRACT(WEEK FROM dr.reward_date) as week_number
FROM daily_rewards dr
JOIN user_nfts un ON dr.user_nft_id = un.id
JOIN nfts n ON un.nft_id = n.id
WHERE n.name = 'SHOGUN NFT 100000'
AND dr.reward_date BETWEEN '2025-01-13' AND '2025-03-07'  -- 週2-9の期間
ORDER BY dr.reward_date
LIMIT 20;

-- 7. 日利率別の分布確認
SELECT 
    dr.daily_rate,
    COUNT(dr.id) as frequency,
    SUM(dr.reward_amount) as total_amount
FROM daily_rewards dr
WHERE dr.reward_date >= '2025-01-13'
AND dr.reward_date <= '2025-05-16'
GROUP BY dr.daily_rate
ORDER BY dr.daily_rate
LIMIT 20;

-- 8. 計算完了ステータス
SELECT 
    'Historical calculation completed' as status,
    COUNT(*) as total_historical_rewards,
    SUM(reward_amount) as total_historical_amount,
    COUNT(DISTINCT user_nft_id) as affected_user_nfts,
    MIN(reward_date) as calculation_start_date,
    MAX(reward_date) as calculation_end_date
FROM daily_rewards 
WHERE reward_date >= '2025-01-13'
AND reward_date <= '2025-05-16';
