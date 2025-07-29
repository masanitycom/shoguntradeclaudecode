-- 紹介システムの監視機能

-- 1. 日次レポート用ビュー
CREATE OR REPLACE VIEW referral_daily_report AS
SELECT 
  DATE(created_at) as registration_date,
  COUNT(*) as new_users,
  COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) as users_with_referrer,
  COUNT(CASE WHEN referrer_id IS NULL THEN 1 END) as users_without_referrer,
  ROUND(COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) as referrer_percentage
FROM users 
WHERE is_admin = false
  AND created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY registration_date DESC;

-- 2. 紹介者パフォーマンス用ビュー
CREATE OR REPLACE VIEW referrer_performance AS
SELECT 
  u2.user_id as referrer_user_id,
  u2.name as referrer_name,
  u2.email as referrer_email,
  u2.created_at as referrer_joined,
  COUNT(u1.id) as total_referrals,
  COUNT(CASE WHEN u1.created_at >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as recent_referrals,
  COUNT(CASE WHEN u1.created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as monthly_referrals,
  MIN(u1.created_at) as first_referral,
  MAX(u1.created_at) as last_referral
FROM users u2
LEFT JOIN users u1 ON u1.referrer_id = u2.id AND u1.is_admin = false
WHERE u2.is_admin = false
GROUP BY u2.id, u2.user_id, u2.name, u2.email, u2.created_at
HAVING COUNT(u1.id) > 0
ORDER BY total_referrals DESC;

-- 3. システムヘルスチェック用関数
CREATE OR REPLACE FUNCTION referral_system_health_check()
RETURNS TABLE(
    metric_name TEXT,
    metric_value NUMERIC,
    status TEXT,
    description TEXT
) AS $$
DECLARE
    total_users INTEGER;
    users_with_referrer INTEGER;
    referrer_percentage NUMERIC;
BEGIN
    -- 基本統計の取得
    SELECT COUNT(*) INTO total_users FROM users WHERE is_admin = false;
    SELECT COUNT(*) INTO users_with_referrer FROM users WHERE referrer_id IS NOT NULL AND is_admin = false;
    referrer_percentage := ROUND(users_with_referrer * 100.0 / total_users, 2);
    
    -- 紹介者カバレッジ
    RETURN QUERY
    SELECT 
        'Referrer Coverage'::TEXT,
        referrer_percentage,
        CASE 
            WHEN referrer_percentage >= 95 THEN 'GOOD'
            WHEN referrer_percentage >= 80 THEN 'WARNING'
            ELSE 'CRITICAL'
        END::TEXT,
        'Percentage of users with referrer'::TEXT;
    
    -- 新規登録の紹介者設定率（過去7日）
    RETURN QUERY
    SELECT 
        'Recent Registration Quality'::TEXT,
        ROUND(
            COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) * 100.0 / 
            NULLIF(COUNT(*), 0), 2
        ),
        CASE 
            WHEN COUNT(*) = 0 THEN 'NO_DATA'
            WHEN COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) * 100.0 / COUNT(*) >= 95 THEN 'GOOD'
            WHEN COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) * 100.0 / COUNT(*) >= 80 THEN 'WARNING'
            ELSE 'CRITICAL'
        END::TEXT,
        'Referrer assignment rate for new users (last 7 days)'::TEXT
    FROM users 
    WHERE is_admin = false 
      AND created_at >= CURRENT_DATE - INTERVAL '7 days';
    
    -- 紹介コードの整合性
    RETURN QUERY
    SELECT 
        'Referral Code Integrity'::TEXT,
        ROUND(
            COUNT(CASE WHEN my_referral_code = user_id THEN 1 END) * 100.0 / 
            COUNT(*), 2
        ),
        CASE 
            WHEN COUNT(CASE WHEN my_referral_code = user_id THEN 1 END) * 100.0 / COUNT(*) >= 99 THEN 'GOOD'
            WHEN COUNT(CASE WHEN my_referral_code = user_id THEN 1 END) * 100.0 / COUNT(*) >= 95 THEN 'WARNING'
            ELSE 'CRITICAL'
        END::TEXT,
        'Percentage of users with correct referral codes'::TEXT
    FROM users 
    WHERE is_admin = false;
END;
$$ LANGUAGE plpgsql;

-- 4. アラート用関数
CREATE OR REPLACE FUNCTION check_referral_alerts()
RETURNS TABLE(
    alert_type TEXT,
    alert_level TEXT,
    message TEXT,
    count BIGINT
) AS $$
BEGIN
    -- 紹介者なしユーザーのアラート
    RETURN QUERY
    SELECT 
        'Missing Referrer'::TEXT,
        'CRITICAL'::TEXT,
        'Users registered without referrer in last 24 hours'::TEXT,
        COUNT(*)::BIGINT
    FROM users 
    WHERE referrer_id IS NULL 
      AND is_admin = false
      AND created_at >= CURRENT_DATE - INTERVAL '1 day'
    HAVING COUNT(*) > 0;
    
    -- 大量登録のアラート
    RETURN QUERY
    SELECT 
        'High Registration Volume'::TEXT,
        'WARNING'::TEXT,
        'Unusually high registration volume in last hour'::TEXT,
        COUNT(*)::BIGINT
    FROM users 
    WHERE is_admin = false
      AND created_at >= NOW() - INTERVAL '1 hour'
    HAVING COUNT(*) > 10;
    
    -- 紹介者の偏りアラート
    RETURN QUERY
    SELECT 
        'Referrer Concentration'::TEXT,
        'WARNING'::TEXT,
        'Single referrer has too many recent referrals'::TEXT,
        MAX(referral_count)::BIGINT
    FROM (
        SELECT 
            u2.user_id,
            COUNT(u1.id) as referral_count
        FROM users u1
        JOIN users u2 ON u1.referrer_id = u2.id
        WHERE u1.is_admin = false
          AND u1.created_at >= CURRENT_DATE - INTERVAL '1 day'
        GROUP BY u2.id, u2.user_id
        HAVING COUNT(u1.id) > 20
    ) high_referrers;
END;
$$ LANGUAGE plpgsql;
