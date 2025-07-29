-- 安全な対象修正の実行

-- 1. 修正対象の最終確認と実行
DO $$
DECLARE
    fix_record RECORD;
    fixes_applied INTEGER := 0;
    backup_coverage NUMERIC;
BEGIN
    -- バックアップカバレッジを確認
    SELECT 
        COUNT(CASE WHEN EXISTS (SELECT 1 FROM users_backup ub WHERE ub.user_id = users.user_id) THEN 1 END) * 100.0 / COUNT(*)
    INTO backup_coverage
    FROM users 
    WHERE is_admin = false;
    
    RAISE NOTICE 'Backup coverage: %', backup_coverage;
    
    -- カバレッジが70%以上の場合のみ修正を実行
    IF backup_coverage >= 70 THEN
        -- バックアップに存在し、修正が必要なユーザーを処理
        FOR fix_record IN 
            SELECT 
                u.id as user_id,
                u.user_id as user_code,
                u.name,
                u.referrer_id as current_referrer_id,
                target_ref.id as target_referrer_id,
                target_ref.user_id as target_referrer_code,
                current_ref.user_id as current_referrer_code
            FROM users u
            JOIN users_backup ub ON u.user_id = ub.user_id
            LEFT JOIN users current_ref ON u.referrer_id = current_ref.id
            LEFT JOIN users_backup backup_ref ON ub.referrer_id = backup_ref.id
            LEFT JOIN users target_ref ON backup_ref.user_id = target_ref.user_id
            WHERE u.is_admin = false
              AND ub.referrer_id IS NOT NULL
              AND backup_ref.user_id IS NOT NULL
              AND target_ref.id IS NOT NULL
              AND (u.referrer_id != target_ref.id OR u.referrer_id IS NULL)
              AND u.user_id IN ('1125Ritsuko', 'Mira', 'NYAN', 'Pin', 'MARIA', 'SHIMA', 'basket', 'yorika1983', 'TY581208', 'Ponchan', 'HIROPON', 'sachiko2', 'Ruitan001', 'tazumao1010', 'ARAHIRO', 'Adamo3588', 'Sasuke001', 'masami', 'kei3803F')
        LOOP
            -- 変更をログに記録
            INSERT INTO referral_change_log (
                user_id,
                user_code,
                old_referrer_id,
                new_referrer_id,
                old_referrer_code,
                new_referrer_code,
                change_reason,
                changed_by
            ) VALUES (
                fix_record.user_id,
                fix_record.user_code,
                fix_record.current_referrer_id,
                fix_record.target_referrer_id,
                fix_record.current_referrer_code,
                fix_record.target_referrer_code,
                'TARGETED_FIX_FROM_BACKUP',
                'SAFE_RESTORATION'
            );
            
            -- 紹介者を修正
            UPDATE users 
            SET referrer_id = fix_record.target_referrer_id,
                updated_at = NOW()
            WHERE id = fix_record.user_id;
            
            fixes_applied := fixes_applied + 1;
            
            RAISE NOTICE 'Fixed %: % -> %', 
                fix_record.user_code, 
                COALESCE(fix_record.current_referrer_code, 'NULL'), 
                fix_record.target_referrer_code;
        END LOOP;
        
        RAISE NOTICE 'Total fixes applied: %', fixes_applied;
    ELSE
        RAISE NOTICE 'Backup coverage too low (%). Only critical fixes will be applied.', backup_coverage;
        
        -- 最低限の修正（1125Ritsukoのみ）
        UPDATE users 
        SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18'),
            updated_at = NOW()
        WHERE user_id = '1125Ritsuko'
          AND EXISTS (SELECT 1 FROM users WHERE user_id = 'USER0a18');
          
        RAISE NOTICE 'Applied critical fix for 1125Ritsuko only';
    END IF;
END $$;

-- 2. 修正結果の確認
SELECT 
    'Fix Results Summary' as check_type,
    COUNT(*) as total_changes,
    COUNT(DISTINCT user_id) as users_affected,
    MIN(changed_at) as first_change,
    MAX(changed_at) as last_change
FROM referral_change_log
WHERE changed_at > NOW() - INTERVAL '1 hour'
  AND change_reason LIKE '%BACKUP%';

-- 3. 重要ユーザーの最終状態確認
SELECT 
    'Critical Users Final Status' as check_type,
    u.user_id,
    u.name,
    ref.user_id as referrer_code,
    ref.name as referrer_name,
    COUNT(referred.id) as referral_count,
    u.updated_at as last_updated
FROM users u
LEFT JOIN users ref ON u.referrer_id = ref.id
LEFT JOIN users referred ON referred.referrer_id = u.id AND referred.is_admin = false
WHERE u.user_id IN ('1125Ritsuko', 'USER0a18', 'bighand1011')
GROUP BY u.id, u.user_id, u.name, ref.user_id, ref.name, u.updated_at
ORDER BY u.user_id;

-- 4. システム全体の健全性チェック
SELECT 
    'System Health After Fixes' as check_type,
    COUNT(*) as total_users,
    COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) as users_with_referrer,
    COUNT(CASE WHEN id = referrer_id THEN 1 END) as self_references,
    COUNT(CASE WHEN referrer_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM users ref WHERE ref.id = users.referrer_id
    ) THEN 1 END) as invalid_referrers,
    ROUND(COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) as referrer_coverage_percent
FROM users 
WHERE is_admin = false;
