-- ユーザーダッシュボード用関数の作成

-- 1. ユーザー個別の報酬情報取得関数
CREATE OR REPLACE FUNCTION get_user_reward_summary(p_user_id UUID)
RETURNS TABLE(
    total_investment NUMERIC,
    total_earned NUMERIC,
    pending_rewards NUMERIC,
    active_nfts INTEGER,
    completed_nfts INTEGER,
    today_rewards NUMERIC,
    this_week_rewards NUMERIC,
    average_daily_rate NUMERIC,
    completion_percentage NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    week_start_date DATE;
BEGIN
    -- 今週の開始日を計算
    week_start_date := CURRENT_DATE - (EXTRACT(DOW FROM CURRENT_DATE)::INTEGER - 1);
    
    RETURN QUERY
    SELECT 
        -- 総投資額
        COALESCE(SUM(COALESCE(un.current_investment, un.purchase_price, 0)), 0) as total_investment,
        
        -- 総獲得額
        COALESCE(SUM(COALESCE(un.total_earned, 0)), 0) as total_earned,
        
        -- 保留中報酬（未申請）
        COALESCE(SUM(
            SELECT COALESCE(SUM(dr.reward_amount), 0)
            FROM daily_rewards dr
            WHERE dr.user_id = p_user_id
            AND dr.is_claimed = false
        ), 0) as pending_rewards,
        
        -- アクティブNFT数
        COUNT(CASE WHEN un.is_active = true THEN 1 END)::INTEGER as active_nfts,
        
        -- 完了NFT数（300%達成）
        COUNT(CASE 
            WHEN COALESCE(un.total_earned, 0) >= COALESCE(un.max_earning, un.purchase_price * 3, 0) 
            THEN 1 
        END)::INTEGER as completed_nfts,
        
        -- 今日の報酬
        COALESCE((
            SELECT SUM(dr.reward_amount)
            FROM daily_rewards dr
            WHERE dr.user_id = p_user_id
            AND dr.reward_date = CURRENT_DATE
        ), 0) as today_rewards,
        
        -- 今週の報酬
        COALESCE((
            SELECT SUM(dr.reward_amount)
            FROM daily_rewards dr
            WHERE dr.user_id = p_user_id
            AND dr.reward_date >= week_start_date
            AND dr.reward_date <= CURRENT_DATE
        ), 0) as this_week_rewards,
        
        -- 平均日利率
        COALESCE((
            SELECT AVG(dr.daily_rate)
            FROM daily_rewards dr
            WHERE dr.user_id = p_user_id
            AND dr.reward_date >= CURRENT_DATE - 30 -- 過去30日
        ), 0) as average_daily_rate,
        
        -- 完了率（%）
        CASE 
            WHEN SUM(COALESCE(un.max_earning, un.purchase_price * 3, 0)) > 0 THEN
                (SUM(COALESCE(un.total_earned, 0)) / SUM(COALESCE(un.max_earning, un.purchase_price * 3, 0))) * 100
            ELSE 0
        END as completion_percentage
        
    FROM user_nfts un
    WHERE un.user_id = p_user_id;
END;
$$;

-- 2. ユーザーのNFT詳細情報取得関数
CREATE OR REPLACE FUNCTION get_user_nft_details(p_user_id UUID)
RETURNS TABLE(
    nft_id UUID,
    nft_name TEXT,
    group_name TEXT,
    purchase_price NUMERIC,
    current_investment NUMERIC,
    total_earned NUMERIC,
    max_earning NUMERIC,
    completion_percentage NUMERIC,
    is_active BOOLEAN,
    purchase_date TIMESTAMP,
    today_reward NUMERIC,
    last_reward_date DATE,
    daily_rate_limit NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        un.nft_id,
        n.name as nft_name,
        drg.group_name,
        un.purchase_price,
        COALESCE(un.current_investment, un.purchase_price, 0) as current_investment,
        COALESCE(un.total_earned, 0) as total_earned,
        COALESCE(un.max_earning, un.purchase_price * 3, 0) as max_earning,
        CASE 
            WHEN COALESCE(un.max_earning, un.purchase_price * 3, 0) > 0 THEN
                (COALESCE(un.total_earned, 0) / COALESCE(un.max_earning, un.purchase_price * 3, 0)) * 100
            ELSE 0
        END as completion_percentage,
        un.is_active,
        un.purchase_date,
        COALESCE((
            SELECT dr.reward_amount
            FROM daily_rewards dr
            WHERE dr.user_nft_id = un.id
            AND dr.reward_date = CURRENT_DATE
            LIMIT 1
        ), 0) as today_reward,
        (
            SELECT MAX(dr.reward_date)
            FROM daily_rewards dr
            WHERE dr.user_nft_id = un.id
        ) as last_reward_date,
        n.daily_rate_limit
    FROM user_nfts un
    JOIN nfts n ON un.nft_id = n.id
    LEFT JOIN daily_rate_groups drg ON n.daily_rate_group_id = drg.id
    WHERE un.user_id = p_user_id
    ORDER BY un.purchase_date DESC;
END;
$$;

-- 3. ユーザーの報酬履歴取得関数
CREATE OR REPLACE FUNCTION get_user_reward_history(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 30
)
RETURNS TABLE(
    reward_date DATE,
    nft_name TEXT,
    investment_amount NUMERIC,
    daily_rate NUMERIC,
    reward_amount NUMERIC,
    is_claimed BOOLEAN,
    reward_type TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dr.reward_date,
        n.name as nft_name,
        dr.investment_amount,
        dr.daily_rate,
        dr.reward_amount,
        COALESCE(dr.is_claimed, false) as is_claimed,
        COALESCE(dr.reward_type, 'DAILY_REWARD') as reward_type
    FROM daily_rewards dr
    JOIN user_nfts un ON dr.user_nft_id = un.id
    JOIN nfts n ON un.nft_id = n.id
    WHERE dr.user_id = p_user_id
    ORDER BY dr.reward_date DESC, dr.created_at DESC
    LIMIT p_limit;
END;
$$;

-- 4. システム全体統計取得関数（ユーザー向け）
CREATE OR REPLACE FUNCTION get_system_public_stats()
RETURNS TABLE(
    total_users INTEGER,
    total_active_nfts INTEGER,
    total_rewards_distributed NUMERIC,
    average_daily_reward NUMERIC,
    top_earning_today NUMERIC,
    system_uptime_days INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM users WHERE is_active = true) as total_users,
        (SELECT COUNT(*)::INTEGER FROM user_nfts WHERE is_active = true) as total_active_nfts,
        (SELECT COALESCE(SUM(reward_amount), 0) FROM daily_rewards) as total_rewards_distributed,
        (SELECT COALESCE(AVG(reward_amount), 0) FROM daily_rewards WHERE reward_date >= CURRENT_DATE - 7) as average_daily_reward,
        (SELECT COALESCE(MAX(reward_amount), 0) FROM daily_rewards WHERE reward_date = CURRENT_DATE) as top_earning_today,
        (SELECT COALESCE(CURRENT_DATE - MIN(reward_date), 0) FROM daily_rewards) as system_uptime_days;
END;
$$;

-- 5. 関数作成完了確認
SELECT 
    '🎯 ユーザーダッシュボード関数作成完了' as status,
    COUNT(*) as created_functions,
    array_agg(routine_name ORDER BY routine_name) as function_names
FROM information_schema.routines 
WHERE routine_name IN (
    'get_user_reward_summary',
    'get_user_nft_details', 
    'get_user_reward_history',
    'get_system_public_stats'
);
