-- 堅牢な紹介システムの構築

-- 1. 改良された紹介者検証関数
CREATE OR REPLACE FUNCTION get_safe_referrer(target_user_id UUID, referrer_user_id TEXT DEFAULT NULL)
RETURNS UUID AS $$
DECLARE
    referrer_id UUID;
    target_created_at TIMESTAMP WITH TIME ZONE;
BEGIN
    -- ターゲットユーザーの作成日時を取得
    SELECT created_at INTO target_created_at 
    FROM users 
    WHERE id = target_user_id;
    
    -- 指定された紹介者をチェック
    IF referrer_user_id IS NOT NULL THEN
        SELECT id INTO referrer_id 
        FROM users 
        WHERE user_id = referrer_user_id 
          AND is_admin = false
          AND id != target_user_id  -- 自己参照防止
          AND (target_created_at IS NULL OR created_at < target_created_at)  -- 日付順序チェック
        LIMIT 1;
    END IF;
    
    -- 指定された紹介者が無効な場合、デフォルト紹介者を選択
    IF referrer_id IS NULL THEN
        SELECT id INTO referrer_id 
        FROM users 
        WHERE is_admin = false
          AND id != target_user_id
          AND (target_created_at IS NULL OR created_at < target_created_at)
        ORDER BY created_at ASC
        LIMIT 1;
    END IF;
    
    -- それでも見つからない場合は最初のユーザーを使用
    IF referrer_id IS NULL THEN
        SELECT id INTO referrer_id 
        FROM users 
        WHERE is_admin = false
          AND id != target_user_id
        ORDER BY created_at ASC
        LIMIT 1;
    END IF;
    
    RETURN referrer_id;
END;
$$ LANGUAGE plpgsql;

-- 2. 改良された登録トリガー
CREATE OR REPLACE FUNCTION secure_referrer_assignment()
RETURNS TRIGGER AS $$
DECLARE
    safe_referrer_id UUID;
BEGIN
    -- 管理者の場合はスキップ
    IF NEW.is_admin = true THEN
        RETURN NEW;
    END IF;
    
    -- 安全な紹介者を取得
    safe_referrer_id := get_safe_referrer(NEW.id, NULL);
    
    -- 紹介者が設定されていない、または無効な場合
    IF NEW.referrer_id IS NULL OR NEW.referrer_id = NEW.id THEN
        NEW.referrer_id := safe_referrer_id;
    ELSE
        -- 指定された紹介者の有効性をチェック
        IF NOT EXISTS (
            SELECT 1 FROM users 
            WHERE id = NEW.referrer_id 
              AND is_admin = false 
              AND id != NEW.id
              AND created_at < NEW.created_at
        ) THEN
            NEW.referrer_id := safe_referrer_id;
        END IF;
    END IF;
    
    -- 紹介コードと紹介リンクの自動設定
    IF NEW.my_referral_code IS NULL OR NEW.my_referral_code = '' THEN
        NEW.my_referral_code := NEW.user_id;
    END IF;
    
    IF NEW.referral_link IS NULL OR NEW.referral_link = '' THEN
        NEW.referral_link := 'https://shogun-trade.vercel.app/register?ref=' || NEW.user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- トリガーの再作成
DROP TRIGGER IF EXISTS trigger_secure_referrer_assignment ON users;
CREATE TRIGGER trigger_secure_referrer_assignment
    BEFORE INSERT OR UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION secure_referrer_assignment();

-- 3. 定期メンテナンス関数
CREATE OR REPLACE FUNCTION maintain_referral_system()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    fixed_count INTEGER := 0;
    temp_count INTEGER;
BEGIN
    -- 自己参照の修正
    UPDATE users 
    SET referrer_id = get_safe_referrer(id, NULL),
        updated_at = NOW()
    WHERE id = referrer_id;
    
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    fixed_count := fixed_count + temp_count;
    result_text := result_text || 'Fixed ' || temp_count || ' self-references. ';
    
    -- 存在しない紹介者の修正
    UPDATE users 
    SET referrer_id = get_safe_referrer(id, NULL),
        updated_at = NOW()
    WHERE referrer_id IS NOT NULL 
      AND NOT EXISTS (SELECT 1 FROM users u2 WHERE u2.id = users.referrer_id)
      AND is_admin = false;
    
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    fixed_count := fixed_count + temp_count;
    result_text := result_text || 'Fixed ' || temp_count || ' invalid referrers. ';
    
    -- 紹介コードの修正
    UPDATE users 
    SET my_referral_code = user_id,
        referral_link = 'https://shogun-trade.vercel.app/register?ref=' || user_id,
        updated_at = NOW()
    WHERE (my_referral_code != user_id OR my_referral_code IS NULL)
      AND is_admin = false;
    
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    result_text := result_text || 'Fixed ' || temp_count || ' referral codes. ';
    
    -- 紹介者なしユーザーの修正
    UPDATE users 
    SET referrer_id = get_safe_referrer(id, NULL),
        updated_at = NOW()
    WHERE referrer_id IS NULL 
      AND is_admin = false;
    
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    fixed_count := fixed_count + temp_count;
    result_text := result_text || 'Fixed ' || temp_count || ' missing referrers. ';
    
    result_text := result_text || 'Total fixes: ' || fixed_count;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- 4. システム整合性チェック関数
CREATE OR REPLACE FUNCTION check_referral_system_integrity()
RETURNS TABLE(
    check_name TEXT,
    status TEXT,
    count BIGINT,
    description TEXT
) AS $$
BEGIN
    -- 基本統計
    RETURN QUERY
    SELECT 
        'Total Users'::TEXT,
        'INFO'::TEXT,
        COUNT(*)::BIGINT,
        'Total non-admin users'::TEXT
    FROM users WHERE is_admin = false;
    
    -- 紹介者カバレッジ
    RETURN QUERY
    SELECT 
        'Referrer Coverage'::TEXT,
        CASE WHEN COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) = COUNT(*) THEN 'PASS' ELSE 'FAIL' END::TEXT,
        COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END)::BIGINT,
        'Users with valid referrer'::TEXT
    FROM users WHERE is_admin = false;
    
    -- 自己参照チェック
    RETURN QUERY
    SELECT 
        'Self Reference Check'::TEXT,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END::TEXT,
        COUNT(*)::BIGINT,
        'Users referring themselves'::TEXT
    FROM users WHERE id = referrer_id;
    
    -- 存在しない紹介者チェック
    RETURN QUERY
    SELECT 
        'Invalid Referrer Check'::TEXT,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END::TEXT,
        COUNT(*)::BIGINT,
        'Users with non-existent referrer'::TEXT
    FROM users u1
    LEFT JOIN users u2 ON u1.referrer_id = u2.id
    WHERE u1.referrer_id IS NOT NULL 
      AND u2.id IS NULL 
      AND u1.is_admin = false;
    
    -- 紹介コード整合性
    RETURN QUERY
    SELECT 
        'Referral Code Integrity'::TEXT,
        CASE WHEN COUNT(CASE WHEN my_referral_code = user_id THEN 1 END) = COUNT(*) THEN 'PASS' ELSE 'FAIL' END::TEXT,
        COUNT(CASE WHEN my_referral_code = user_id THEN 1 END)::BIGINT,
        'Users with correct referral codes'::TEXT
    FROM users WHERE is_admin = false;
END;
$$ LANGUAGE plpgsql;
