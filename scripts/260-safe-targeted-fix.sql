-- 安全な部分修正：重要ユーザーのみの修正

-- 1. 1125Ritsukoの問題を安全に修正
-- まず現在の状況を記録
CREATE TEMP TABLE temp_1125ritsuko_fix AS
SELECT 
    u.id as user_id,
    u.user_id as user_code,
    u.name,
    u.referrer_id as current_referrer_id,
    ref.user_id as current_referrer_code,
    ref.name as current_referrer_name,
    ub.referrer_id as backup_referrer_id,
    backup_ref.user_id as backup_referrer_code
FROM users u
LEFT JOIN users ref ON u.referrer_id = ref.id
LEFT JOIN users_backup ub ON u.user_id = ub.user_id
LEFT JOIN users_backup backup_ref ON ub.referrer_id = backup_ref.id
WHERE u.user_id = '1125Ritsuko';

-- 現在の状況を表示
SELECT 
    'Before Fix - 1125Ritsuko Status' as check_type,
    user_code,
    name,
    current_referrer_code,
    current_referrer_name,
    backup_referrer_code,
    CASE 
        WHEN current_referrer_code = backup_referrer_code THEN 'CORRECT'
        ELSE 'NEEDS_FIX'
    END as status
FROM temp_1125ritsuko_fix;

-- 2. USER0a18が存在することを確認
SELECT 
    'USER0a18 Verification' as check_type,
    user_id,
    name,
    email,
    created_at,
    CASE WHEN id IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END as status
FROM users 
WHERE user_id = 'USER0a18';

-- 3. 安全な修正実行（USER0a18が存在する場合のみ）
DO $$
DECLARE
    user0a18_id UUID;
    ritsuko_id UUID;
    current_referrer_code TEXT;
BEGIN
    -- USER0a18のIDを取得
    SELECT id INTO user0a18_id FROM users WHERE user_id = 'USER0a18';
    
    -- 1125RitsukoのIDを取得
    SELECT id INTO ritsuko_id FROM users WHERE user_id = '1125Ritsuko';
    
    -- 現在の紹介者を確認
    SELECT ref.user_id INTO current_referrer_code
    FROM users u
    LEFT JOIN users ref ON u.referrer_id = ref.id
    WHERE u.user_id = '1125Ritsuko';
    
    IF user0a18_id IS NOT NULL AND ritsuko_id IS NOT NULL THEN
        -- 修正前の状態をログに記録
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
            ritsuko_id,
            '1125Ritsuko',
            (SELECT referrer_id FROM users WHERE id = ritsuko_id),
            user0a18_id,
            current_referrer_code,
            'USER0a18',
            'EMERGENCY_FIX_FROM_BACKUP',
            'MANUAL_RESTORATION'
        );
        
        -- 1125RitsukoのreferrerをUSER0a18に修正
        UPDATE users 
        SET referrer_id = user0a18_id,
            updated_at = NOW()
        WHERE id = ritsuko_id;
        
        RAISE NOTICE '1125Ritsuko referrer fixed: % -> USER0a18', current_referrer_code;
    ELSE
        RAISE NOTICE 'Cannot fix: USER0a18 or 1125Ritsuko not found';
    END IF;
END $$;

-- 4. 修正後の確認
SELECT 
    'After Fix - 1125Ritsuko Status' as check_type,
    u.user_id,
    u.name,
    ref.user_id as referrer_code,
    ref.name as referrer_name,
    u.updated_at as last_updated
FROM users u
LEFT JOIN users ref ON u.referrer_id = ref.id
WHERE u.user_id = '1125Ritsuko';

-- 5. 1125Ritsukoの紹介者数確認
SELECT 
    'Ritsuko Referrals After Fix' as check_type,
    COUNT(*) as total_referrals,
    MIN(referred.created_at) as earliest_referral,
    MAX(referred.created_at) as latest_referral
FROM users referred
WHERE referred.referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');
