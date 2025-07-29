-- 緊急調査: 破壊された紹介関係の詳細分析

-- 1. 1125Ritsukoの正しい情報を確認
SELECT 
    'Current 1125Ritsuko Status' as check_type,
    u.user_id,
    u.name,
    u.email,
    u.created_at,
    u.referrer_id,
    ref.user_id as current_referrer_user_id,
    ref.name as current_referrer_name,
    ref.email as current_referrer_email
FROM users u
LEFT JOIN users ref ON u.referrer_id = ref.id
WHERE u.user_id = '1125Ritsuko';

-- 2. USER0a18の情報を確認
SELECT 
    'USER0a18 Status' as check_type,
    u.user_id,
    u.name,
    u.email,
    u.created_at,
    u.id as user_uuid
FROM users u
WHERE u.user_id = 'USER0a18';

-- 3. 現在1125Ritsukoを紹介者としているユーザー数
SELECT 
    'Users with 1125Ritsuko as Referrer' as check_type,
    COUNT(*) as total_count,
    MIN(u.created_at) as earliest_referral,
    MAX(u.created_at) as latest_referral
FROM users u
JOIN users ref ON u.referrer_id = ref.id
WHERE ref.user_id = '1125Ritsuko';

-- 4. 最近の更新履歴（updated_atが最近のもの）
SELECT 
    'Recent Updates' as check_type,
    u.user_id,
    u.name,
    u.created_at as user_created,
    u.updated_at as last_updated,
    ref.user_id as referrer_user_id,
    ref.name as referrer_name
FROM users u
LEFT JOIN users ref ON u.referrer_id = ref.id
WHERE u.updated_at > NOW() - INTERVAL '10 minutes'
  AND u.is_admin = false
ORDER BY u.updated_at DESC
LIMIT 20;

-- 5. 作成日時と紹介者の関係チェック（異常なパターンを検出）
SELECT 
    'Date Anomaly Check' as check_type,
    COUNT(*) as anomaly_count,
    'Users with referrer created after them' as description
FROM users u
JOIN users ref ON u.referrer_id = ref.id
WHERE u.created_at < ref.created_at
  AND u.is_admin = false;

-- 6. 全ユーザーの紹介者分布（上位20人）
SELECT 
    'Current Referrer Distribution' as check_type,
    ref.user_id as referrer_user_id,
    ref.name as referrer_name,
    ref.created_at as referrer_created,
    COUNT(u.id) as referral_count
FROM users u
JOIN users ref ON u.referrer_id = ref.id
WHERE u.is_admin = false
GROUP BY ref.id, ref.user_id, ref.name, ref.created_at
ORDER BY referral_count DESC
LIMIT 20;
