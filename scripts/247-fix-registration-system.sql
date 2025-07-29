-- 登録システムの修正と予防策

-- 1. 紹介コードと紹介リンクの正規化
UPDATE users 
SET 
  my_referral_code = user_id,
  referral_link = 'https://shogun-trade.vercel.app/register?ref=' || user_id,
  updated_at = NOW()
WHERE my_referral_code != user_id 
   OR referral_link != 'https://shogun-trade.vercel.app/register?ref=' || user_id
   OR my_referral_code IS NULL 
   OR referral_link IS NULL;

-- 2. 紹介者検証関数の作成
CREATE OR REPLACE FUNCTION validate_referrer(referrer_user_id TEXT)
RETURNS UUID AS $$
DECLARE
    referrer_id UUID;
BEGIN
    -- 紹介者が存在するかチェック
    SELECT id INTO referrer_id 
    FROM users 
    WHERE user_id = referrer_user_id 
      AND is_admin = false
    LIMIT 1;
    
    -- 見つからない場合はデフォルト紹介者を返す
    IF referrer_id IS NULL THEN
        SELECT id INTO referrer_id 
        FROM users 
        WHERE is_admin = false
          AND created_at < '2025-06-22 00:00:00'
        ORDER BY created_at
        LIMIT 1;
    END IF;
    
    RETURN referrer_id;
END;
$$ LANGUAGE plpgsql;

-- 3. 新規ユーザー登録時の紹介者自動設定トリガー
CREATE OR REPLACE FUNCTION set_referrer_on_insert()
RETURNS TRIGGER AS $$
DECLARE
    default_referrer_id UUID;
BEGIN
    -- 紹介者が設定されていない場合
    IF NEW.referrer_id IS NULL AND NEW.is_admin = false THEN
        -- デフォルト紹介者を設定
        SELECT id INTO default_referrer_id 
        FROM users 
        WHERE is_admin = false
          AND created_at < NOW() - INTERVAL '1 day'
        ORDER BY created_at
        LIMIT 1;
        
        IF default_referrer_id IS NOT NULL THEN
            NEW.referrer_id := default_referrer_id;
        END IF;
    END IF;
    
    -- 紹介コードと紹介リンクを自動設定
    IF NEW.my_referral_code IS NULL THEN
        NEW.my_referral_code := NEW.user_id;
    END IF;
    
    IF NEW.referral_link IS NULL THEN
        NEW.referral_link := 'https://shogun-trade.vercel.app/register?ref=' || NEW.user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- トリガーの作成
DROP TRIGGER IF EXISTS trigger_set_referrer_on_insert ON users;
CREATE TRIGGER trigger_set_referrer_on_insert
    BEFORE INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION set_referrer_on_insert();

-- 4. 紹介関係の整合性チェック関数
CREATE OR REPLACE FUNCTION check_referral_integrity()
RETURNS TABLE(
    check_type TEXT,
    issue_count BIGINT,
    description TEXT
) AS $$
BEGIN
    -- 紹介者なしユーザー
    RETURN QUERY
    SELECT 
        'Missing Referrer'::TEXT,
        COUNT(*)::BIGINT,
        'Users without referrer'::TEXT
    FROM users 
    WHERE referrer_id IS NULL AND is_admin = false;
    
    -- 自己参照
    RETURN QUERY
    SELECT 
        'Self Reference'::TEXT,
        COUNT(*)::BIGINT,
        'Users referring themselves'::TEXT
    FROM users 
    WHERE id = referrer_id;
    
    -- 存在しない紹介者
    RETURN QUERY
    SELECT 
        'Invalid Referrer'::TEXT,
        COUNT(*)::BIGINT,
        'Users with non-existent referrer'::TEXT
    FROM users u1
    LEFT JOIN users u2 ON u1.referrer_id = u2.id
    WHERE u1.referrer_id IS NOT NULL 
      AND u2.id IS NULL 
      AND u1.is_admin = false;
    
    -- 紹介コード不整合
    RETURN QUERY
    SELECT 
        'Referral Code Mismatch'::TEXT,
        COUNT(*)::BIGINT,
        'Users with incorrect referral codes'::TEXT
    FROM users 
    WHERE my_referral_code != user_id 
      AND is_admin = false;
END;
$$ LANGUAGE plpgsql;

-- 5. 定期的な整合性チェックのスケジュール設定用関数
CREATE OR REPLACE FUNCTION fix_referral_issues()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    fixed_count INTEGER := 0;
BEGIN
    -- 紹介者なしユーザーの修正
    WITH default_referrer AS (
        SELECT id FROM users 
        WHERE is_admin = false
          AND created_at < NOW() - INTERVAL '1 day'
        ORDER BY created_at
        LIMIT 1
    )
    UPDATE users 
    SET referrer_id = (SELECT id FROM default_referrer)
    WHERE referrer_id IS NULL 
      AND is_admin = false;
    
    GET DIAGNOSTICS fixed_count = ROW_COUNT;
    result_text := result_text || 'Fixed ' || fixed_count || ' users without referrer. ';
    
    -- 紹介コードの修正
    UPDATE users 
    SET my_referral_code = user_id,
        referral_link = 'https://shogun-trade.vercel.app/register?ref=' || user_id
    WHERE (my_referral_code != user_id OR my_referral_code IS NULL)
      AND is_admin = false;
    
    GET DIAGNOSTICS fixed_count = ROW_COUNT;
    result_text := result_text || 'Fixed ' || fixed_count || ' referral codes.';
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;
