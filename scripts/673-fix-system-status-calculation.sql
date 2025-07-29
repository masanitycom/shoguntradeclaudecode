-- システム状況表示の修正

-- 1. 総報酬額計算関数の修正
CREATE OR REPLACE FUNCTION get_total_rewards()
RETURNS DECIMAL(10,2)
LANGUAGE plpgsql
AS $$
DECLARE
    total_amount DECIMAL(10,2);
BEGIN
    SELECT COALESCE(SUM(reward_amount), 0) 
    INTO total_amount
    FROM daily_rewards;
    
    RETURN total_amount;
END;
$$;

-- 2. アクティブNFT数計算関数の修正
CREATE OR REPLACE FUNCTION get_active_nft_count()
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    nft_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO nft_count
    FROM user_nfts
    WHERE is_active = true;
    
    RETURN nft_count;
END;
$$;

-- 3. 総ユーザー数計算関数の修正
CREATE OR REPLACE FUNCTION get_total_user_count()
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    user_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO user_count
    FROM users
    WHERE id IS NOT NULL;
    
    RETURN user_count;
END;
$$;

-- 4. 保留中申請数計算関数の修正
CREATE OR REPLACE FUNCTION get_pending_applications()
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    pending_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO pending_count
    FROM nft_purchase_applications
    WHERE status = 'pending';
    
    RETURN pending_count;
END;
$$;

-- 5. 権限設定
GRANT EXECUTE ON FUNCTION get_total_rewards() TO authenticated;
GRANT EXECUTE ON FUNCTION get_active_nft_count() TO authenticated;
GRANT EXECUTE ON FUNCTION get_total_user_count() TO authenticated;
GRANT EXECUTE ON FUNCTION get_pending_applications() TO authenticated;

-- 6. 現在のシステム状況を確認
SELECT 
    get_total_user_count() as total_users,
    get_active_nft_count() as active_nfts,
    get_pending_applications() as pending_applications,
    get_total_rewards() as total_rewards;
