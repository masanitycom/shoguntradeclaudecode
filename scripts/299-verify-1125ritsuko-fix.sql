-- 🔍 1125Ritsuko修正結果の検証

-- 1125Ritsukoの紹介数確認（0人であるべき）
SELECT 
    '1125Ritsuko紹介数確認' as check_type,
    COUNT(*) as referral_count,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ 成功（0人）'
        ELSE '❌ まだ' || COUNT(*) || '人残っている'
    END as status
FROM users
WHERE referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko');

-- 1125Ritsuko自身の状態確認
SELECT 
    '1125Ritsuko自身の状態' as check_type,
    u.user_id,
    u.name,
    COALESCE(r.user_id, 'なし') as referrer,
    (SELECT COUNT(*) FROM users WHERE referrer_id = u.id) as current_referral_count
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.user_id = '1125Ritsuko';

-- USER0a18の紹介数確認（修正後に増加しているはず）
SELECT 
    'USER0a18の紹介数' as check_type,
    COUNT(*) as referral_count,
    '1125Ritsukoと修正された26人を含む' as note
FROM users
WHERE referrer_id = (SELECT id FROM users WHERE user_id = 'USER0a18');

-- 修正されたユーザーの確認（バックアップテーブルがあれば）
SELECT 
    '修正されたユーザー確認' as check_type,
    u.user_id,
    u.name,
    COALESCE(r.user_id, 'なし') as current_referrer
FROM users u
LEFT JOIN users r ON u.referrer_id = r.id
WHERE u.user_id IN (
    '242424b', 'atsuko03', 'atsuko04', 'atsuko28', 'Ayanon2', 'Ayanon3',
    'FU3111', 'FU9166', 'itsumari0311', 'ko1969', 'kuru39', 'MAU1204',
    'mitsuaki0320', 'mook0214', 'NYAN', 'USER037', 'USER038', 'USER039',
    'USER040', 'USER041', 'USER042', 'USER043', 'USER044', 'USER045',
    'USER046', 'USER047'
)
ORDER BY u.user_id;

-- 最終結果メッセージ
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM users WHERE referrer_id = (SELECT id FROM users WHERE user_id = '1125Ritsuko')) = 0
        THEN '🎉 完璧！1125Ritsukoの紹介数は0人になりました！'
        ELSE '❌ まだ修正が必要です'
    END as final_result;
