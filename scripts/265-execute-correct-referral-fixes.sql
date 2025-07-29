-- 正しい紹介関係に基づく修正実行（CSVデータ準拠・修正版）

-- 1. 修正前の状態を記録
DO $$
BEGIN
    -- 一時テーブルを作成
    DROP TABLE IF EXISTS pre_fix_status;
    CREATE TEMP TABLE pre_fix_status AS
    SELECT 
        u.id,
        u.user_id,
        u.name,
        u.email,
        u.referrer_id as old_referrer_id,
        ref.user_id as old_referrer_code,
        ref.name as old_referrer_name,
        u.updated_at as last_updated
    FROM users u
    LEFT JOIN users ref ON u.referrer_id = ref.id
    WHERE u.user_id IN ('OHTAKIYO', '1125Ritsuko', 'Mira', 'klmiklmi0204', 'USER0a18', 'bighand1011');
    
    RAISE NOTICE '📋 修正前の状態を記録しました';
END $$;

-- 修正前の状態を表示
SELECT 
    'Pre-Fix Status' as check_type,
    user_id,
    name,
    email,
    old_referrer_code as current_referrer,
    old_referrer_name as current_referrer_name
FROM pre_fix_status
ORDER BY user_id;

-- 2. 正しい紹介関係の修正実行
DO $$
DECLARE
    fix_record RECORD;
    target_referrer_id UUID;
    fixes_applied INTEGER := 0;
    current_referrer_id UUID;
    current_referrer_code TEXT;
    user_exists BOOLEAN;
BEGIN
    RAISE NOTICE '🔧 CSVデータに基づく紹介関係修正を開始...';
    RAISE NOTICE '';
    
    -- 各ユーザーの正しい紹介関係を修正
    FOR fix_record IN 
        SELECT * FROM (VALUES
            ('OHTAKIYO', 'klmiklmi0204', 'CSVデータによる正しい紹介関係'),
            ('1125Ritsuko', 'USER0a18', 'CSVデータによる正しい紹介関係'),
            ('USER0a18', NULL, 'CSVデータでは紹介者なし'),
            ('bighand1011', NULL, 'CSVデータでは紹介者なし'),
            ('Mira', NULL, 'CSVデータでは紹介者なし'),
            ('klmiklmi0204', NULL, 'CSVデータでは紹介者なし')
        ) AS fixes(user_code, correct_referrer_code, reason)
    LOOP
        -- ユーザーが存在するか確認
        SELECT EXISTS (SELECT 1 FROM users WHERE user_id = fix_record.user_code) INTO user_exists;
        
        IF NOT user_exists THEN
            RAISE NOTICE '⚠️ %: ユーザーが存在しません', fix_record.user_code;
            CONTINUE;
        END IF;
        
        -- 現在の紹介者を確認
        SELECT u.referrer_id, ref.user_id 
        INTO current_referrer_id, current_referrer_code
        FROM users u
        LEFT JOIN users ref ON u.referrer_id = ref.id
        WHERE u.user_id = fix_record.user_code;
        
        -- 正しい紹介者のIDを取得（NULLの場合はスキップ）
        IF fix_record.correct_referrer_code IS NOT NULL THEN
            SELECT id INTO target_referrer_id 
            FROM users 
            WHERE user_id = fix_record.correct_referrer_code;
            
            IF target_referrer_id IS NULL THEN
                RAISE NOTICE '❌ %: 紹介者 % が見つかりません', 
                    fix_record.user_code, 
                    fix_record.correct_referrer_code;
                CONTINUE;
            END IF;
        ELSE
            target_referrer_id := NULL;
        END IF;
        
        -- 既に正しい場合はスキップ
        IF (target_referrer_id IS NULL AND current_referrer_id IS NULL) OR
           (target_referrer_id IS NOT NULL AND current_referrer_id = target_referrer_id) THEN
            RAISE NOTICE '✅ %: 既に正しい紹介関係です (紹介者: %)', 
                fix_record.user_code, 
                COALESCE(fix_record.correct_referrer_code, 'なし');
            CONTINUE;
        END IF;
        
        -- 変更ログを記録
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
            u.id,
            fix_record.user_code,
            u.referrer_id,
            target_referrer_id,
            current_referrer_code,
            fix_record.correct_referrer_code,
            fix_record.reason,
            'CSV_DATA_CORRECTION'
        FROM users u
        WHERE u.user_id = fix_record.user_code;
        
        -- 紹介者を修正
        UPDATE users 
        SET referrer_id = target_referrer_id,
            updated_at = NOW()
        WHERE user_id = fix_record.user_code;
        
        fixes_applied := fixes_applied + 1;
        
        RAISE NOTICE '🔄 %: % → % に修正', 
            fix_record.user_code,
            COALESCE(current_referrer_code, 'なし'),
            COALESCE(fix_record.correct_referrer_code, 'なし');
    END LOOP;
    
    RAISE NOTICE '';
    RAISE NOTICE '✅ 修正完了: %件の紹介関係を修正しました', fixes_applied;
END $$;

-- 3. 修正後の確認
SELECT 
    'After Fix Status' as check_type,
    u.user_id,
    u.name,
    u.email,
    ref.user_id as current_referrer,
    ref.name as referrer_name,
    CASE 
        WHEN u.user_id = 'OHTAKIYO' AND ref.user_id = 'klmiklmi0204' THEN 'CORRECT ✅'
        WHEN u.user_id = '1125Ritsuko' AND ref.user_id = 'USER0a18' THEN 'CORRECT ✅'
        WHEN u.user_id IN ('USER0a18', 'bighand1011', 'Mira', 'klmiklmi0204') AND ref.user_id IS NULL THEN 'CORRECT ✅'
        WHEN ref.user_id IS NULL THEN 'NO_REFERRER ⚠️'
        ELSE 'CHECK_NEEDED ❓'
    END as status,
    u.updated_at as last_updated
FROM users u
LEFT JOIN users ref ON u.referrer_id = ref.id
WHERE u.user_id IN ('OHTAKIYO', '1125Ritsuko', 'Mira', 'klmiklmi0204', 'USER0a18', 'bighand1011')
ORDER BY u.user_id;

-- 4. 修正結果のサマリー
SELECT 
    'Fix Summary' as check_type,
    COUNT(*) as total_changes,
    COUNT(DISTINCT user_id) as users_affected,
    MIN(changed_at) as first_change,
    MAX(changed_at) as last_change,
    string_agg(DISTINCT change_reason, ', ') as reasons
FROM referral_change_log
WHERE changed_at > NOW() - INTERVAL '1 hour'
  AND changed_by = 'CSV_DATA_CORRECTION';

-- 5. 重要ユーザーの紹介者数確認
SELECT 
    'Important Users Referral Count' as check_type,
    u.user_id,
    u.name,
    COUNT(referred.id) as referral_count,
    COUNT(CASE WHEN referred.email LIKE '%@shogun-trade.com' THEN 1 END) as proxy_email_referrals,
    COUNT(CASE WHEN referred.email NOT LIKE '%@shogun-trade.com' THEN 1 END) as real_email_referrals
FROM users u
LEFT JOIN users referred ON referred.referrer_id = u.id AND referred.is_admin = false
WHERE u.user_id IN ('OHTAKIYO', '1125Ritsuko', 'USER0a18', 'klmiklmi0204', 'Mira', 'bighand1011')
GROUP BY u.id, u.user_id, u.name
ORDER BY referral_count DESC, u.user_id;

-- 6. システム健全性の最終確認
SELECT 
    'Final System Health' as check_type,
    COUNT(*) as total_users,
    COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) as users_with_referrer,
    ROUND(COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) as referrer_percentage,
    COUNT(CASE WHEN id = referrer_id THEN 1 END) as self_references,
    COUNT(CASE WHEN referrer_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM users ref WHERE ref.id = users.referrer_id
    ) THEN 1 END) as invalid_referrers,
    COUNT(CASE WHEN email LIKE '%@shogun-trade.com' THEN 1 END) as proxy_email_users
FROM users 
WHERE is_admin = false;

-- 7. 変更ログの確認
SELECT 
    'Change Log Review' as check_type,
    user_code,
    old_referrer_code,
    new_referrer_code,
    change_reason,
    changed_at
FROM referral_change_log
WHERE changed_by = 'CSV_DATA_CORRECTION'
  AND changed_at > NOW() - INTERVAL '1 hour'
ORDER BY changed_at DESC;

-- 8. 循環参照の最終確認
WITH RECURSIVE referral_check AS (
    SELECT 
        u.user_id,
        u.name,
        u.referrer_id,
        ref.user_id as referrer_code,
        1 as depth,
        ARRAY[u.user_id] as path
    FROM users u
    LEFT JOIN users ref ON u.referrer_id = ref.id
    WHERE u.user_id IN ('OHTAKIYO', '1125Ritsuko', 'USER0a18', 'bighand1011', 'Mira', 'klmiklmi0204')
    
    UNION ALL
    
    SELECT 
        rc.user_id,
        rc.name,
        next_ref.referrer_id,
        next_ref_user.user_id,
        rc.depth + 1,
        rc.path || next_ref_user.user_id
    FROM referral_check rc
    JOIN users next_ref ON rc.referrer_id = next_ref.id
    LEFT JOIN users next_ref_user ON next_ref.referrer_id = next_ref_user.id
    WHERE rc.depth < 5 
      AND next_ref_user.user_id IS NOT NULL
      AND NOT (next_ref_user.user_id = ANY(rc.path))
)
SELECT 
    'Final Circular Reference Check' as check_type,
    user_id,
    name,
    array_to_string(path, ' -> ') as referral_path,
    CASE 
        WHEN array_length(path, 1) > 1 THEN 'CHAIN_EXISTS'
        ELSE 'NO_CHAIN'
    END as status
FROM referral_check
WHERE depth = (SELECT MAX(depth) FROM referral_check rc2 WHERE rc2.user_id = referral_check.user_id)
ORDER BY user_id;
