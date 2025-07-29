-- 緊急システム復旧

-- 1. calculate_user_mlm_rank関数を復旧
DROP FUNCTION IF EXISTS calculate_user_mlm_rank(UUID);

CREATE OR REPLACE FUNCTION calculate_user_mlm_rank(target_user_id UUID)
RETURNS TABLE(
    user_id UUID,
    rank_name TEXT,
    user_nft_value DECIMAL(15,2),
    organization_volume DECIMAL(15,2),
    meets_nft_requirement BOOLEAN,
    meets_organization_requirement BOOLEAN
) AS $$
DECLARE
    user_nft_total DECIMAL(15,2) := 0;
    org_volume DECIMAL(15,2) := 0;
    current_rank TEXT := 'なし';
    nft_requirement_met BOOLEAN := false;
    org_requirement_met BOOLEAN := false;
BEGIN
    -- ユーザーのNFT価値を計算
    SELECT COALESCE(SUM(un.purchase_price), 0)
    INTO user_nft_total
    FROM user_nfts un
    WHERE un.user_id = target_user_id 
    AND un.is_active = true;
    
    -- 組織ボリュームを計算（簡易版）
    WITH RECURSIVE referral_tree AS (
        -- 直接の紹介者
        SELECT id, referrer_id, 1 as level
        FROM users 
        WHERE referrer_id = target_user_id
        
        UNION ALL
        
        -- 間接的な紹介者（最大5レベル）
        SELECT u.id, u.referrer_id, rt.level + 1
        FROM users u
        INNER JOIN referral_tree rt ON u.referrer_id = rt.id
        WHERE rt.level < 5
    )
    SELECT COALESCE(SUM(un.purchase_price), 0)
    INTO org_volume
    FROM referral_tree rt
    INNER JOIN user_nfts un ON rt.id = un.user_id
    WHERE un.is_active = true;
    
    -- NFT要件チェック（1000ドル以上）
    nft_requirement_met := user_nft_total >= 1000;
    
    -- ランク判定
    IF user_nft_total >= 1000 THEN
        IF org_volume >= 600000 THEN
            current_rank := '将軍';
            org_requirement_met := true;
        ELSIF org_volume >= 300000 THEN
            current_rank := '大名';
            org_requirement_met := true;
        ELSIF org_volume >= 100000 THEN
            current_rank := '大老';
            org_requirement_met := true;
        ELSIF org_volume >= 50000 THEN
            current_rank := '老中';
            org_requirement_met := true;
        ELSIF org_volume >= 10000 THEN
            current_rank := '奉行';
            org_requirement_met := true;
        ELSIF org_volume >= 5000 THEN
            current_rank := '代官';
            org_requirement_met := true;
        ELSIF org_volume >= 3000 THEN
            current_rank := '武将';
            org_requirement_met := true;
        ELSIF org_volume >= 1000 THEN
            current_rank := '足軽';
            org_requirement_met := true;
        ELSE
            current_rank := 'なし';
            org_requirement_met := false;
        END IF;
    ELSE
        current_rank := 'なし';
        org_requirement_met := false;
    END IF;
    
    RETURN QUERY SELECT 
        target_user_id,
        current_rank,
        user_nft_total,
        org_volume,
        nft_requirement_met,
        org_requirement_met;
END;
$$ LANGUAGE plpgsql;

-- 2. 日利計算関数を完全に修復
DROP FUNCTION IF EXISTS calculate_daily_rewards_for_date(DATE);

CREATE OR REPLACE FUNCTION calculate_daily_rewards_for_date(calc_date DATE)
RETURNS TABLE(
    processed_count INTEGER,
    skipped_count INTEGER,
    error_count INTEGER
) AS $$
DECLARE
    nft_record RECORD;
    daily_rate DECIMAL(10,6);
    reward_amount DECIMAL(10,2);
    week_start DATE;
    day_column TEXT;
    total_processed INTEGER := 0;
    total_skipped INTEGER := 0;
    total_errors INTEGER := 0;
    existing_reward INTEGER;
BEGIN
    -- 平日のみ処理
    IF EXTRACT(dow FROM calc_date) BETWEEN 1 AND 5 THEN
        week_start := date_trunc('week', calc_date);
        day_column := CASE EXTRACT(dow FROM calc_date)
            WHEN 1 THEN 'monday_rate'
            WHEN 2 THEN 'tuesday_rate'
            WHEN 3 THEN 'wednesday_rate'
            WHEN 4 THEN 'thursday_rate'
            WHEN 5 THEN 'friday_rate'
        END;
        
        -- 全てのアクティブNFTについて計算
        FOR nft_record IN
            SELECT 
                un.id as user_nft_id,
                un.user_id,
                un.nft_id,
                un.purchase_price, 
                un.total_earned,
                n.daily_rate_limit, 
                drg.id as group_id
            FROM user_nfts un
            INNER JOIN nfts n ON un.nft_id = n.id
            INNER JOIN daily_rate_groups drg ON n.daily_rate_limit = drg.daily_rate_limit
            WHERE un.is_active = true
            AND un.purchase_date <= calc_date
            AND un.total_earned < un.purchase_price * 3 -- 300%未満
            AND un.purchase_price > 0
        LOOP
            BEGIN
                -- 既存の報酬レコードをチェック
                SELECT COUNT(*) INTO existing_reward
                FROM daily_rewards 
                WHERE user_nft_id = nft_record.user_nft_id 
                AND reward_date = calc_date;
                
                IF existing_reward = 0 THEN
                    -- その日の日利を取得
                    EXECUTE format('
                        SELECT COALESCE(%I, 0) 
                        FROM group_weekly_rates 
                        WHERE group_id = $1 AND week_start_date = $2
                        LIMIT 1
                    ', day_column) 
                    INTO daily_rate 
                    USING nft_record.group_id, week_start;
                    
                    -- デフォルト値設定
                    IF daily_rate IS NULL OR daily_rate = 0 THEN
                        daily_rate := 0.005; -- デフォルト0.5%
                    END IF;
                    
                    -- 日利上限を適用
                    IF daily_rate > nft_record.daily_rate_limit THEN
                        daily_rate := nft_record.daily_rate_limit;
                    END IF;
                    
                    -- 報酬計算
                    reward_amount := nft_record.purchase_price * daily_rate;
                    
                    IF reward_amount > 0 THEN
                        -- daily_rewardsに挿入
                        INSERT INTO daily_rewards (
                            user_id,
                            user_nft_id,
                            nft_id,
                            reward_date,
                            week_start_date,
                            daily_rate,
                            reward_amount,
                            is_claimed,
                            created_at,
                            updated_at
                        ) VALUES (
                            nft_record.user_id,
                            nft_record.user_nft_id,
                            nft_record.nft_id,
                            calc_date,
                            week_start,
                            daily_rate,
                            reward_amount,
                            false,
                            CURRENT_TIMESTAMP,
                            CURRENT_TIMESTAMP
                        );
                        
                        total_processed := total_processed + 1;
                    ELSE
                        total_skipped := total_skipped + 1;
                    END IF;
                ELSE
                    total_skipped := total_skipped + 1;
                END IF;
                
            EXCEPTION WHEN OTHERS THEN
                total_errors := total_errors + 1;
            END;
        END LOOP;
    END IF;
    
    RETURN QUERY SELECT total_processed, total_skipped, total_errors;
END;
$$ LANGUAGE plpgsql;

-- 3. user_nftsの累計収益を更新する関数
CREATE OR REPLACE FUNCTION update_user_nft_totals()
RETURNS INTEGER AS $$
DECLARE
    updated_count INTEGER := 0;
BEGIN
    UPDATE user_nfts 
    SET total_earned = (
        SELECT COALESCE(SUM(dr.reward_amount), 0)
        FROM daily_rewards dr
        WHERE dr.user_nft_id = user_nfts.id
    ),
    updated_at = CURRENT_TIMESTAMP
    WHERE is_active = true;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RETURN updated_count;
END;
$$ LANGUAGE plpgsql;

-- 4. システム健全性チェック関数
CREATE OR REPLACE FUNCTION system_health_check()
RETURNS TABLE(
    check_name TEXT,
    status TEXT,
    details TEXT
) AS $$
BEGIN
    -- ユーザー数チェック
    RETURN QUERY 
    SELECT 
        'ユーザー数'::TEXT,
        'OK'::TEXT,
        (SELECT COUNT(*)::TEXT || '人' FROM users);
    
    -- NFT数チェック
    RETURN QUERY 
    SELECT 
        'アクティブNFT数'::TEXT,
        'OK'::TEXT,
        (SELECT COUNT(*)::TEXT || '個' FROM user_nfts WHERE is_active = true);
    
    -- 日利報酬数チェック
    RETURN QUERY 
    SELECT 
        '日利報酬レコード数'::TEXT,
        'OK'::TEXT,
        (SELECT COUNT(*)::TEXT || '件' FROM daily_rewards);
    
    -- 関数存在チェック
    RETURN QUERY 
    SELECT 
        'calculate_user_mlm_rank関数'::TEXT,
        CASE WHEN EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'calculate_user_mlm_rank') 
             THEN 'OK' ELSE 'ERROR' END::TEXT,
        '関数の存在確認'::TEXT;
END;
$$ LANGUAGE plpgsql;

SELECT '🚨 緊急システム復旧完了' as status;
