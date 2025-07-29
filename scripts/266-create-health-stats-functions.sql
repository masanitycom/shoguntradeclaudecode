-- システム健全性統計関数の作成

-- 循環参照チェック関数
CREATE OR REPLACE FUNCTION check_circular_references()
RETURNS TABLE(user_id TEXT, referrer_id UUID, depth INTEGER) AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE referral_chain AS (
        -- 初期クエリ：すべてのユーザー
        SELECT 
            u.user_id::TEXT,
            u.referrer_id,
            1 as depth,
            ARRAY[u.id] as path
        FROM users u
        WHERE u.referrer_id IS NOT NULL
        
        UNION ALL
        
        -- 再帰クエリ：紹介チェーンを辿る
        SELECT 
            rc.user_id,
            u.referrer_id,
            rc.depth + 1,
            rc.path || u.id
        FROM referral_chain rc
        JOIN users u ON rc.referrer_id = u.id
        WHERE u.referrer_id IS NOT NULL 
        AND rc.depth < 10
        AND NOT (u.id = ANY(rc.path)) -- 循環検出
    )
    SELECT DISTINCT
        rc.user_id,
        rc.referrer_id,
        rc.depth
    FROM referral_chain rc
    JOIN users u ON rc.referrer_id = u.id
    WHERE u.id = ANY(
        SELECT unnest(path[1:array_length(path,1)-1]) 
        FROM referral_chain 
        WHERE user_id = rc.user_id
    );
END;
$$ LANGUAGE plpgsql;

-- 無効な紹介者チェック関数
CREATE OR REPLACE FUNCTION check_invalid_referrers()
RETURNS TABLE(user_id TEXT, invalid_referrer_id UUID) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.user_id::TEXT,
        u.referrer_id
    FROM users u
    WHERE u.referrer_id IS NOT NULL
    AND NOT EXISTS (
        SELECT 1 FROM users r WHERE r.id = u.referrer_id
    );
END;
$$ LANGUAGE plpgsql;

-- 紹介関係変更ログ関数
CREATE OR REPLACE FUNCTION log_referral_change(
    p_user_id TEXT,
    p_old_referrer TEXT,
    p_new_referrer TEXT,
    p_reason TEXT,
    p_change_type TEXT DEFAULT 'MANUAL'
)
RETURNS TEXT AS $$
DECLARE
    log_message TEXT;
BEGIN
    log_message := format(
        'User: %s | Old: %s | New: %s | Reason: %s | Type: %s | Time: %s',
        p_user_id,
        COALESCE(p_old_referrer, 'NULL'),
        COALESCE(p_new_referrer, 'NULL'),
        p_reason,
        p_change_type,
        NOW()
    );
    
    -- ログをテーブルに保存（テーブルが存在する場合）
    BEGIN
        INSERT INTO referral_change_logs (
            user_id, old_referrer, new_referrer, reason, change_type, created_at
        ) VALUES (
            p_user_id, p_old_referrer, p_new_referrer, p_reason, p_change_type, NOW()
        );
    EXCEPTION WHEN undefined_table THEN
        -- テーブルが存在しない場合は無視
        NULL;
    END;
    
    RETURN log_message;
END;
$$ LANGUAGE plpgsql;

-- システム健全性統計関数
CREATE OR REPLACE FUNCTION create_health_stats_function()
RETURNS TABLE(
    metric_name TEXT,
    metric_value BIGINT,
    status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'total_users'::TEXT,
        COUNT(*)::BIGINT,
        '✅ Normal'::TEXT
    FROM users
    
    UNION ALL
    
    SELECT 
        'users_with_referrer'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) > 0 THEN '✅ Normal' ELSE '⚠️ Warning' END::TEXT
    FROM users WHERE referrer_id IS NOT NULL
    
    UNION ALL
    
    SELECT 
        'circular_references'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) = 0 THEN '✅ Normal' ELSE '❌ Error' END::TEXT
    FROM check_circular_references()
    
    UNION ALL
    
    SELECT 
        'invalid_referrers'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) = 0 THEN '✅ Normal' ELSE '❌ Error' END::TEXT
    FROM check_invalid_referrers()
    
    UNION ALL
    
    SELECT 
        'proxy_email_users'::TEXT,
        COUNT(*)::BIGINT,
        '📧 Info'::TEXT
    FROM users WHERE email LIKE '%@shogun-trade.com';
END;
$$ LANGUAGE plpgsql;

SELECT 'システム健全性統計関数が正常に作成されました' as status;
