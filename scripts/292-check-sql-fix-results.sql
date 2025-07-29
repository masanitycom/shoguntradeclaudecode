-- 🔍 SQL修正結果の確認

-- 1. 重要ユーザーの修正状況確認
SELECT 
    '=== 重要ユーザーの修正確認 ===' as check_type,
    u.user_id,
    u.name,
    COALESCE(r.user_id, 'なし') as current_referrer,
    CASE 
        WHEN u.user_id = '1125Ritsuko' THEN 'USER0a18'
        WHEN u.user_id = 'kazukazu2' THEN 'kazukazu1'
        WHEN u.user_id = 'yatchan002' THEN 'yatchan'
        WHEN u.user_id = 'yatchan003' THEN 'yatchan'
        WHEN u.user_id = 'bighand1011' THEN 'USER0a18'
        WHEN u.user_id = 'klmiklmi0204' THEN 'yasui001'
        WHEN u.user_id = 'Mira' THEN 'Mickey'
        WHEN u.user_id = 'OHTAKIYO' THEN 'klmiklmi0204'
        ELSE '不明'
    END as should_be,
    CASE 
        WHEN (u.user_id = '1125Ritsuko' AND COALESCE(r.user_id, '') = 'USER0a18') OR
             (u.user_id = 'kazukazu2' AND COALESCE(r.user_id, '') = 'kazukazu1') OR
             (u.user_id = 'yatchan002' AND COALESCE(r.user_id, '') = 'yatchan') OR
             (u.user_id = 'yatchan003' AND COALESCE(r.user_id, '') = 'yatchan') OR
             (u.user_id = 'bighand1011' AND COALESCE(r.user_id, '') = 'USER0a18') OR
             (u.user_id = 'klmiklmi0204' AND COALESCE(r.user_id, '') = 'yasui001') OR
             (u.user_id = 'Mira' AND COALESCE(r.user_id, '') = 'Mickey') OR
             (u.user_id = 'OHTAKIYO' AND COALESCE(r.user_id, '') = 'klmiklmi0204')
        THEN '✅ 正しい'
        ELSE '❌ 間違い'
    END as status
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.user_id IN ('1125Ritsuko', 'kazukazu2', 'yatchan002', 'yatchan003', 'bighand1011', 'klmiklmi0204', 'Mira', 'OHTAKIYO')
ORDER BY u.user_id;

-- 2. 1125Ritsukoの詳細確認
SELECT 
    '=== 1125Ritsuko詳細確認 ===' as check_type,
    u.user_id,
    u.name,
    u.referrer_id,
    COALESCE(r.user_id, 'なし') as referrer_user_id,
    COALESCE(r.name, 'なし') as referrer_name,
    CASE 
        WHEN r.user_id = 'USER0a18' THEN '✅ 正しい (USER0a18)'
        WHEN r.user_id IS NULL THEN '❌ 紹介者なし'
        ELSE '❌ 間違った紹介者: ' || r.user_id
    END as status
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.user_id = '1125Ritsuko';

-- 3. 1125Ritsukoの紹介数確認
SELECT 
    '=== 1125Ritsukoの紹介数 ===' as check_type,
    COUNT(*) as direct_referrals
FROM users u
WHERE u.referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- 4. USER0a18の紹介数確認
SELECT 
    '=== USER0a18の紹介数 ===' as check_type,
    COUNT(*) as direct_referrals
FROM users u
WHERE u.referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18');

-- 5. 修正されたユーザー数確認
SELECT 
    '=== 修正統計 ===' as check_type,
    COUNT(*) as total_modified
FROM users u
JOIN referral_backup_final b ON u.id = b.id
WHERE u.referrer_id != b.referrer_id 
   OR (u.referrer_id IS NULL) != (b.referrer_id IS NULL);

-- 6. バックアップとの比較サンプル
SELECT 
    '=== 修正例 (最初の10件) ===' as check_type,
    u.user_id,
    u.name,
    COALESCE(old_r.user_id, 'なし') as old_referrer,
    COALESCE(new_r.user_id, 'なし') as new_referrer
FROM users u
JOIN referral_backup_final b ON u.id = b.id
LEFT JOIN users old_r ON b.referrer_id = old_r.id
LEFT JOIN users new_r ON u.referrer_id = new_r.id
WHERE u.referrer_id != b.referrer_id 
   OR (u.referrer_id IS NULL) != (b.referrer_id IS NULL)
LIMIT 10;
