-- 緊急復元: バックアップデータから正しい紹介関係を復元

-- 1. バックアップデータの確認
SELECT 
    'Backup Data Verification' as check_type,
    user_id,
    name,
    email,
    referrer_id,
    (SELECT user_id FROM users WHERE id = users_backup.referrer_id) as referrer_user_id
FROM users_backup 
WHERE user_id IN ('1125Ritsuko', 'USER0a18')
ORDER BY user_id;

-- 2. 現在の破損状況の確認
SELECT 
    'Current Broken State' as check_type,
    u.user_id,
    u.name,
    ref.user_id as current_referrer_user_id,
    ref.name as current_referrer_name,
    COUNT(referred.id) as current_referral_count
FROM users u
LEFT JOIN users ref ON u.referrer_id = ref.id
LEFT JOIN users referred ON referred.referrer_id = u.id AND referred.is_admin = false
WHERE u.user_id IN ('1125Ritsuko', 'USER0a18')
GROUP BY u.id, u.user_id, u.name, ref.user_id, ref.name
ORDER BY u.user_id;

-- 3. バックアップから正しい紹介関係を復元
-- まず、1125Ritsukoの紹介者をUSER0a18に修正
UPDATE users 
SET referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18'),
    updated_at = NOW()
WHERE user_id = '1125Ritsuko';

-- 4. 現在1125Ritsukoを紹介者としているユーザーを適切に再配置
-- バックアップデータに基づいて正しい紹介関係を復元
WITH backup_referrals AS (
    SELECT 
        ub.user_id,
        ub.referrer_id as backup_referrer_id,
        u.id as current_user_id,
        ref_backup.user_id as backup_referrer_user_id
    FROM users_backup ub
    JOIN users u ON ub.user_id = u.user_id
    LEFT JOIN users_backup ref_backup ON ub.referrer_id = ref_backup.id
    WHERE ub.referrer_id IS NOT NULL
      AND u.is_admin = false
),
correct_referrals AS (
    SELECT 
        br.current_user_id,
        br.user_id,
        br.backup_referrer_user_id,
        correct_ref.id as correct_referrer_id
    FROM backup_referrals br
    LEFT JOIN users correct_ref ON br.backup_referrer_user_id = correct_ref.user_id
    WHERE correct_ref.id IS NOT NULL
)
UPDATE users 
SET referrer_id = cr.correct_referrer_id,
    updated_at = NOW()
FROM correct_referrals cr
WHERE users.id = cr.current_user_id
  AND users.referrer_id != cr.correct_referrer_id;

-- 5. 復元結果の確認
SELECT 
    'Restoration Results' as check_type,
    COUNT(*) as total_users,
    COUNT(CASE WHEN referrer_id IS NOT NULL THEN 1 END) as users_with_referrer,
    COUNT(CASE WHEN id = referrer_id THEN 1 END) as self_referrals,
    ROUND(AVG(CASE WHEN referrer_id IS NOT NULL THEN 1.0 ELSE 0.0 END) * 100, 2) as referrer_coverage_percent
FROM users 
WHERE is_admin = false;

-- 6. 重要ユーザーの状況確認
SELECT 
    'Key Users After Restoration' as check_type,
    u.user_id,
    u.name,
    ref.user_id as referrer_user_id,
    ref.name as referrer_name,
    COUNT(referred.id) as referral_count
FROM users u
LEFT JOIN users ref ON u.referrer_id = ref.id
LEFT JOIN users referred ON referred.referrer_id = u.id AND referred.is_admin = false
WHERE u.user_id IN ('1125Ritsuko', 'USER0a18', 'bighand1011')
GROUP BY u.id, u.user_id, u.name, ref.user_id, ref.name
ORDER BY u.user_id;

-- 7. 紹介者分布の確認（復元後）
SELECT 
    'Referrer Distribution After Restoration' as check_type,
    ref.user_id as referrer_user_id,
    ref.name as referrer_name,
    COUNT(u.id) as referral_count
FROM users u
JOIN users ref ON u.referrer_id = ref.id
WHERE u.is_admin = false
GROUP BY ref.id, ref.user_id, ref.name
HAVING COUNT(u.id) > 2
ORDER BY referral_count DESC
LIMIT 20;
