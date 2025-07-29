-- 紹介システム保護機能の実装

-- 1. 紹介関係変更ログテーブル
CREATE TABLE IF NOT EXISTS referral_change_log (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
    user_code TEXT,
    old_referrer_id UUID,
    new_referrer_id UUID,
    old_referrer_code TEXT,
    new_referrer_code TEXT,
    change_reason TEXT,
    changed_by TEXT DEFAULT 'SYSTEM',
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 紹介関係変更を記録するトリガー関数
CREATE OR REPLACE FUNCTION log_referrer_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- 紹介者が変更された場合のみログを記録
    IF OLD.referrer_id IS DISTINCT FROM NEW.referrer_id THEN
        INSERT INTO referral_change_log (
            user_id,
            user_code,
            old_referrer_id,
            new_referrer_id,
            old_referrer_code,
            new_referrer_code,
            change_reason,
            changed_by
        )
        SELECT 
            NEW.id,
            NEW.user_id,
            OLD.referrer_id,
            NEW.referrer_id,
            old_ref.user_id,
            new_ref.user_id,
            'REFERRER_UPDATED',
            'SYSTEM'
        FROM users old_ref, users new_ref
        WHERE old_ref.id = OLD.referrer_id
          AND new_ref.id = NEW.referrer_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- トリガーの作成
DROP TRIGGER IF EXISTS trigger_log_referrer_changes ON users;
CREATE TRIGGER trigger_log_referrer_changes
    AFTER UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION log_referrer_changes();

-- 3. 紹介関係の整合性チェック関数
CREATE OR REPLACE FUNCTION check_referral_integrity()
RETURNS TABLE(
    issue_type TEXT,
    user_id TEXT,
    user_name TEXT,
    issue_description TEXT,
    severity TEXT
) AS $$
BEGIN
    -- 自己参照チェック
    RETURN QUERY
    SELECT 
        'SELF_REFERENCE'::TEXT,
        u.user_id,
        u.name,
        'User is referring themselves'::TEXT,
        'CRITICAL'::TEXT
    FROM users u
    WHERE u.id = u.referrer_id;
    
    -- 存在しない紹介者チェック
    RETURN QUERY
    SELECT 
        'INVALID_REFERRER'::TEXT,
        u.user_id,
        u.name,
        'Referrer does not exist'::TEXT,
        'CRITICAL'::TEXT
    FROM users u
    WHERE u.referrer_id IS NOT NULL 
      AND NOT EXISTS (SELECT 1 FROM users ref WHERE ref.id = u.referrer_id)
      AND u.is_admin = false;
    
    -- 日付論理エラーチェック
    RETURN QUERY
    SELECT 
        'DATE_LOGIC_ERROR'::TEXT,
        u.user_id,
        u.name,
        'User created before their referrer'::TEXT,
        'WARNING'::TEXT
    FROM users u
    JOIN users ref ON u.referrer_id = ref.id
    WHERE u.created_at <= ref.created_at
      AND u.is_admin = false;
    
    -- 紹介者なしチェック
    RETURN QUERY
    SELECT 
        'MISSING_REFERRER'::TEXT,
        u.user_id,
        u.name,
        'User has no referrer'::TEXT,
        'WARNING'::TEXT
    FROM users u
    WHERE u.referrer_id IS NULL 
      AND u.is_admin = false;
END;
$$ LANGUAGE plpgsql;

-- 4. 自動修復関数
CREATE OR REPLACE FUNCTION auto_fix_referral_issues()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    fixed_count INTEGER := 0;
    temp_count INTEGER;
BEGIN
    -- 自己参照の修正
    WITH self_refs AS (
        SELECT id, user_id
        FROM users 
        WHERE id = referrer_id
    )
    UPDATE users 
    SET referrer_id = (
        SELECT id 
        FROM users potential_ref 
        WHERE potential_ref.is_admin = false
          AND potential_ref.created_at < users.created_at
          AND potential_ref.id != users.id
        ORDER BY potential_ref.created_at DESC
        LIMIT 1
    ),
    updated_at = NOW()
    WHERE id IN (SELECT id FROM self_refs);
    
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    fixed_count := fixed_count + temp_count;
    result_text := result_text || 'Fixed ' || temp_count || ' self-references. ';
    
    -- 存在しない紹介者の修正
    UPDATE users 
    SET referrer_id = (
        SELECT id 
        FROM users potential_ref 
        WHERE potential_ref.is_admin = false
          AND potential_ref.created_at < users.created_at
          AND potential_ref.id != users.id
        ORDER BY potential_ref.created_at DESC
        LIMIT 1
    ),
    updated_at = NOW()
    WHERE referrer_id IS NOT NULL 
      AND NOT EXISTS (SELECT 1 FROM users u2 WHERE u2.id = users.referrer_id)
      AND is_admin = false;
    
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    fixed_count := fixed_count + temp_count;
    result_text := result_text || 'Fixed ' || temp_count || ' invalid referrers. ';
    
    -- 紹介者なしユーザーの修正
    UPDATE users 
    SET referrer_id = (
        SELECT id 
        FROM users potential_ref 
        WHERE potential_ref.is_admin = false
          AND potential_ref.created_at < users.created_at
          AND potential_ref.id != users.id
        ORDER BY potential_ref.created_at DESC
        LIMIT 1
    ),
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

-- 5. 定期メンテナンス用のバッチ関数
CREATE OR REPLACE FUNCTION daily_referral_maintenance()
RETURNS TEXT AS $$
DECLARE
    integrity_issues INTEGER;
    fix_result TEXT;
BEGIN
    -- 整合性チェック
    SELECT COUNT(*) INTO integrity_issues
    FROM check_referral_integrity();
    
    -- 問題がある場合は自動修復
    IF integrity_issues > 0 THEN
        SELECT auto_fix_referral_issues() INTO fix_result;
        
        -- ログに記録
        INSERT INTO referral_change_log (
            user_id,
            user_code,
            change_reason,
            changed_by
        ) VALUES (
            NULL,
            'SYSTEM_MAINTENANCE',
            'Daily maintenance found ' || integrity_issues || ' issues: ' || fix_result,
            'AUTO_MAINTENANCE'
        );
        
        RETURN 'Found ' || integrity_issues || ' issues. ' || fix_result;
    ELSE
        RETURN 'No issues found. System healthy.';
    END IF;
END;
$$ LANGUAGE plpgsql;
